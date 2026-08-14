// SPDX-License-Identifier: MIT

// Driven from GridLayer, which stays off the main actor because CALayer's
// overrides are nonisolated. The types here are explicitly nonisolated so the
// app target's MainActor default does not reach them.

import AppKit
import CoreText
import Metal
import NimbCore
import NimbState

final nonisolated class GridMetalSceneBuilder {
  private let renderer: GridMetalRenderer
  private var glyphAtlas: GridMetalGlyphAtlas? = nil

  init(renderer: GridMetalRenderer) {
    self.renderer = renderer
  }

  func makeFrame(
    snapshot: GridDrawSnapshot,
    bounds: CGRect,
    scale: CGFloat,
  )
  -> GridPreparedMetalFrame? {
    guard let glyphAtlas = prepareGlyphAtlas(scale: scale) else {
      return nil
    }

    return .init(
      scene: buildScene(snapshot: snapshot, bounds: bounds, glyphAtlas: glyphAtlas, scale: scale),
      atlasTexture: glyphAtlas.texture,
      clearColor: snapshot.appearance.defaultBackgroundColor.metalClearColor,
    )
  }

  private func prepareGlyphAtlas(scale: CGFloat) -> GridMetalGlyphAtlas? {
    if let glyphAtlas, abs(glyphAtlas.scale - scale) < 0.001 {
      return glyphAtlas
    }

    let glyphAtlas = GridMetalGlyphAtlas(renderer: renderer, scale: scale)
    self.glyphAtlas = glyphAtlas
    return glyphAtlas
  }

  private func buildScene(
    snapshot: GridDrawSnapshot,
    bounds: CGRect,
    glyphAtlas: GridMetalGlyphAtlas,
    scale: CGFloat,
  )
  -> GridMetalScene {
    var scene = GridMetalScene()

    let boundingRect = IntegerRectangle(
      frame: bounds.applying(snapshot.upsideDownTransform),
      cellSize: snapshot.font.cellSize,
    )
    let visibleRowDrawRuns = snapshot.grid.drawRuns.visibleRowDrawRuns(
      boundingRect: boundingRect,
      font: snapshot.font,
      upsideDownTransform: snapshot.upsideDownTransform,
    )

    for rowDrawRuns in visibleRowDrawRuns {
      for visibleDrawRun in rowDrawRuns.drawRuns {
        let drawRun = visibleDrawRun.drawRun
        let rect = visibleDrawRun.rect
        scene.backgroundQuads.append(
          quadInstance(
            rect: rect,
            color: snapshot.appearance.backgroundColor(for: drawRun.highlightID).metal,
          ),
        )

        appendDecorationInstances(
          for: drawRun,
          rect: rect,
          font: snapshot.font,
          appearance: snapshot.appearance,
          scale: scale,
          to: &scene.decorationQuads,
        )

        if let glyphRuns = drawRun.glyphRuns {
          appendGlyphInstances(
            glyphRuns,
            in: rect,
            color: snapshot.appearance.foregroundColor(for: drawRun.highlightID).metal,
            glyphAtlas: glyphAtlas,
            to: &scene.glyphInstances,
          )
        }
      }
    }

    if
      snapshot.cursorBlinkingPhase,
      snapshot.isMouseUserInteractionEnabled,
      let cursorDrawRun = snapshot.grid.drawRuns.cursorDrawRun,
      boundingRect.contains(cursorDrawRun.origin)
    {
      appendCursorInstances(
        cursorDrawRun,
        snapshot: snapshot,
        glyphAtlas: glyphAtlas,
        to: &scene,
      )
    }

    return scene
  }

  private func appendGlyphInstances(
    _ glyphRuns: [GlyphRun],
    in rect: CGRect,
    color: SIMD4<Float>,
    glyphAtlas: GridMetalGlyphAtlas,
    clipRect: CGRect? = nil,
    to glyphInstances: inout [GridMetalGlyphInstance],
  ) {
    for glyphRun in glyphRuns {
      for index in glyphRun.glyphs.indices {
        guard let entry = glyphAtlas.entry(for: glyphRun.glyphs[index], font: glyphRun.appKitFont) else {
          continue
        }

        let glyphRect = CGRect(
          x: rect.origin.x + glyphRun.positions[index].x + CGFloat(entry.origin.x),
          y: rect.origin.y + glyphRun.positions[index].y + CGFloat(entry.origin.y),
          width: CGFloat(entry.size.x),
          height: CGFloat(entry.size.y),
        )

        if
          let clipRect,
          let clippedInstance = clippedGlyphInstance(
            rect: glyphRect,
            uvOrigin: entry.uvOrigin,
            uvSize: entry.uvSize,
            color: color,
            clipRect: clipRect,
          )
        {
          glyphInstances.append(clippedInstance)
        } else if clipRect == nil {
          glyphInstances.append(
            .init(
              origin: .init(Float(glyphRect.origin.x), Float(glyphRect.origin.y)),
              size: .init(Float(glyphRect.width), Float(glyphRect.height)),
              uvOrigin: entry.uvOrigin,
              uvSize: entry.uvSize,
              color: color,
            ),
          )
        }
      }
    }
  }

  private func appendCursorInstances(
    _ cursorDrawRun: CursorDrawRun,
    snapshot: GridDrawSnapshot,
    glyphAtlas: GridMetalGlyphAtlas,
    to scene: inout GridMetalScene,
  ) {
    let cursorForegroundColor: Color
    let cursorBackgroundColor: Color

    if cursorDrawRun.highlightID == .zero {
      cursorForegroundColor = snapshot.appearance.defaultBackgroundColor
      cursorBackgroundColor = snapshot.appearance.defaultForegroundColor
    } else {
      cursorForegroundColor = snapshot.appearance.foregroundColor(for: cursorDrawRun.highlightID)
      cursorBackgroundColor = snapshot.appearance.backgroundColor(for: cursorDrawRun.highlightID)
    }

    let offset = cursorDrawRun.origin * snapshot.font.cellSize
    let cursorRect = cursorDrawRun.cellFrame
      .offsetBy(dx: offset.x, dy: offset.y)
      .applying(snapshot.upsideDownTransform)

    scene.cursorQuads.append(
      quadInstance(rect: cursorRect, color: cursorBackgroundColor.metal),
    )

    if
      cursorDrawRun.shouldDrawParentText,
      let glyphRuns = cursorDrawRun.parentDrawRun.glyphRuns
    {
      let parentRectangle = IntegerRectangle(
        origin: .init(column: cursorDrawRun.parentOrigin.column, row: cursorDrawRun.parentOrigin.row),
        size: .init(columnsCount: cursorDrawRun.parentDrawRun.columnsCount, rowsCount: 1),
      )
      let parentRect = (parentRectangle * snapshot.font.cellSize)
        .applying(snapshot.upsideDownTransform)

      appendGlyphInstances(
        glyphRuns,
        in: parentRect,
        color: cursorForegroundColor.metal,
        glyphAtlas: glyphAtlas,
        clipRect: cursorRect,
        to: &scene.cursorGlyphInstances,
      )
    }
  }

  private func appendDecorationInstances(
    for drawRun: DrawRun,
    rect: CGRect,
    font: Font,
    appearance: Appearance,
    scale: CGFloat,
    to quads: inout [GridMetalQuadInstance],
  ) {
    guard case let .cells(cells) = drawRun.rowPartContent else {
      return
    }

    let decorations = appearance.decorations(for: drawRun.highlightID)
    guard decorations != .init() else {
      return
    }

    let color = appearance.specialColor(for: drawRun.highlightID).metal
    let thickness = max(1 / max(scale, 1), 0.5)
    let underlineY = rect.origin.y + 0.5

    if decorations.isStrikethrough {
      quads.append(
        quadInstance(
          rect: .init(x: rect.minX, y: rect.midY - thickness / 2, width: rect.width, height: thickness),
          color: color,
        ),
      )
    }

    if decorations.isUnderline {
      quads.append(
        quadInstance(
          rect: .init(x: rect.minX, y: underlineY, width: rect.width, height: thickness),
          color: color,
        ),
      )
    } else if decorations.isUnderdashed {
      appendPatternedLineQuads(
        fromX: rect.minX,
        toX: rect.maxX,
        y: underlineY,
        segmentWidth: 2,
        gapWidth: 2,
        thickness: thickness,
        color: color,
        to: &quads,
      )
    } else if decorations.isUnderdotted {
      appendPatternedLineQuads(
        fromX: rect.minX,
        toX: rect.maxX,
        y: underlineY,
        segmentWidth: 1,
        gapWidth: 1,
        thickness: thickness,
        color: color,
        to: &quads,
      )
    } else if decorations.isUnderdouble {
      quads.append(
        quadInstance(
          rect: .init(x: rect.minX, y: underlineY, width: rect.width, height: thickness),
          color: color,
        ),
      )
      quads.append(
        quadInstance(
          rect: .init(x: rect.minX, y: underlineY + 3, width: rect.width, height: thickness),
          color: color,
        ),
      )
    } else if decorations.isUndercurl {
      let widthDivider = 3
      let xStep = font.cellWidth / Double(widthDivider)
      let pointsCount = cells.count * widthDivider + 1
      let oddUnderlineY = underlineY + 3
      let evenUnderlineY = underlineY

      for index in 0 ..< pointsCount {
        let isEven = index.isMultiple(of: 2)
        let x = rect.minX + Double(index) * xStep
        let y = isEven ? evenUnderlineY : oddUnderlineY
        quads.append(
          quadInstance(
            rect: .init(x: x, y: y, width: thickness, height: thickness),
            color: color,
          ),
        )
      }
    }
  }

  private func appendPatternedLineQuads(
    fromX: CGFloat,
    toX: CGFloat,
    y: CGFloat,
    segmentWidth: CGFloat,
    gapWidth: CGFloat,
    thickness: CGFloat,
    color: SIMD4<Float>,
    to quads: inout [GridMetalQuadInstance],
  ) {
    var currentX = fromX
    while currentX < toX {
      let width = min(segmentWidth, toX - currentX)
      quads.append(
        quadInstance(
          rect: .init(x: currentX, y: y, width: width, height: thickness),
          color: color,
        ),
      )
      currentX += segmentWidth + gapWidth
    }
  }

  private func quadInstance(
    rect: CGRect,
    color: SIMD4<Float>,
  )
  -> GridMetalQuadInstance {
    .init(
      origin: .init(Float(rect.origin.x), Float(rect.origin.y)),
      size: .init(Float(rect.width), Float(rect.height)),
      color: color,
    )
  }

  private func clippedGlyphInstance(
    rect: CGRect,
    uvOrigin: SIMD2<Float>,
    uvSize: SIMD2<Float>,
    color: SIMD4<Float>,
    clipRect: CGRect,
  )
  -> GridMetalGlyphInstance? {
    let intersection = rect.intersection(clipRect)
    guard !intersection.isNull, !intersection.isEmpty, rect.width > 0, rect.height > 0 else {
      return nil
    }

    let left = Float((intersection.minX - rect.minX) / rect.width)
    let right = Float((rect.maxX - intersection.maxX) / rect.width)
    let bottom = Float((intersection.minY - rect.minY) / rect.height)
    let top = Float((rect.maxY - intersection.maxY) / rect.height)

    return .init(
      origin: .init(Float(intersection.origin.x), Float(intersection.origin.y)),
      size: .init(Float(intersection.width), Float(intersection.height)),
      uvOrigin: .init(
        uvOrigin.x + uvSize.x * left,
        uvOrigin.y + uvSize.y * top,
      ),
      uvSize: .init(
        uvSize.x * max(0, 1 - left - right),
        uvSize.y * max(0, 1 - top - bottom),
      ),
      color: color,
    )
  }
}

nonisolated extension Color {
  var metal: SIMD4<Float> {
    let color = appKit.usingColorSpace(.deviceRGB) ?? appKit
    return .init(
      Float(color.redComponent),
      Float(color.greenComponent),
      Float(color.blueComponent),
      Float(color.alphaComponent),
    )
  }

  var metalClearColor: MTLClearColor {
    let metal = metal
    return .init(
      red: Double(metal.x),
      green: Double(metal.y),
      blue: Double(metal.z),
      alpha: Double(metal.w),
    )
  }
}
