// SPDX-License-Identifier: MIT

// Explicitly nonisolated, so the app target's MainActor default does not reach
// types driven from GridLayer's nonisolated CALayer overrides.

import AppKit
import CoreText
import Metal
import NimbCore
import NimbState

final nonisolated class GridMetalSceneBuilder {
  /// One row's geometry, in the coordinates it was built at. Kept whole so an
  /// unchanged row can be copied out again rather than rebuilt.
  private struct CachedRow {
    var slot: Int
    var originY: CGFloat
    var backgroundQuads: [GridMetalQuadInstance] = []
    var decorationQuads: [GridMetalQuadInstance] = []
    var glyphInstances: [GridMetalGlyphInstance] = []
  }

  /// Everything a cached row depends on other than its own content; a change to
  /// any of it invalidates every row. Colours are baked into cached vertices.
  private struct CacheContext: Equatable {
    var fontID: Int
    var scale: CGFloat
    var columns: Range<Int>
  }

  private let renderer: GridMetalRenderer
  /// Instance counts from the previous frame, used to size this frame's arrays
  /// up front rather than growing them from empty.
  private var previousSceneCounts = GridMetalSceneCounts()

  /// This frame's rows, keyed by row id. `carriedRows` holds last frame's;
  /// whatever is left in it scrolled off or was rebuilt, and is dropped.
  private var cachedRows: [RowDrawRun.ID: CachedRow] = [:]
  private var carriedRows: [RowDrawRun.ID: CachedRow] = [:]
  private var cacheContext: CacheContext? = nil

  /// Row slots handed out to cached rows, and the ones going spare. A slot is
  /// baked into the row's instances, so it outlives scrolling. Zero is reserved.
  private var nextSlot = 1
  private var freeSlots: [Int] = []

  init(renderer: GridMetalRenderer) {
    self.renderer = renderer
  }

  func makeFrame(
    snapshot: GridDrawSnapshot,
    updates: State.Updates,
    bounds: CGRect,
    scale: CGFloat,
  )
  -> GridPreparedMetalFrame? {
    guard let glyphAtlas = renderer.glyphAtlas(scale: scale) else {
      return nil
    }

    let scene = measuringRenderStage("scene build", .sceneBuild) {
      buildScene(
        snapshot: snapshot,
        updates: updates,
        bounds: bounds,
        glyphAtlas: glyphAtlas,
        scale: scale,
      )
    }

    return .init(
      scene: scene,
      atlasTexture: glyphAtlas.texture,
      clearColor: snapshot.appearance.defaultBackgroundColor.metalClearColor,
    )
  }

  private func takeSlot() -> Int {
    if let slot = freeSlots.popLast() {
      return slot
    }
    defer { nextSlot += 1 }
    return nextSlot
  }

  private func releaseSlots(of rows: some Sequence<CachedRow>) {
    for row in rows {
      freeSlots.append(row.slot)
    }
  }

  private func buildScene(
    snapshot: GridDrawSnapshot,
    updates: State.Updates,
    bounds: CGRect,
    glyphAtlas: GridMetalGlyphAtlas,
    scale: CGFloat,
  )
  -> GridMetalScene {
    var scene = GridMetalScene()
    previousSceneCounts.reserve(in: &scene)

    let boundingRect = IntegerRectangle(
      frame: bounds.applying(snapshot.upsideDownTransform),
      cellSize: snapshot.font.cellSize,
    )

    let context = CacheContext(
      fontID: snapshot.font.id,
      scale: scale,
      columns: boundingRect.columns,
    )
    if cacheContext != context || updates.isAppearanceUpdated || updates.isHighlightsUpdated {
      releaseSlots(of: cachedRows.values)
      cachedRows.removeAll(keepingCapacity: true)
      cacheContext = context
    }

    swap(&cachedRows, &carriedRows)
    // Whatever is still in cachedRows belonged to rows dropped a frame ago;
    // their slots go back on the free list before this frame hands any out.
    releaseSlots(of: cachedRows.values)
    cachedRows.removeAll(keepingCapacity: true)

    // A row at a time rather than a draw run at a time: the row's id moves with
    // its contents, so an unchanged row stays recognisable after a scroll.
    snapshot.grid.drawRuns.forEachVisibleRow(
      boundingRect: boundingRect,
      font: snapshot.font,
    ) { rowDrawRun, rowOrigin in
      let rowOriginY = CGRect(
        x: 0,
        y: rowOrigin.y,
        width: 0,
        height: snapshot.font.cellHeight,
      )
      .applying(snapshot.upsideDownTransform)
      .origin.y

      // Taken out once, so the slot is still in hand if the reuse check below
      // declines, rather than stranding it and allocating a fresh one.
      let carried = carriedRows.removeValue(forKey: rowDrawRun.id)

      if let carried {
        let delta = rowOriginY - carried.originY
        // Cached glyph origins are snapped to whole device pixels, so the row
        // can only shift by a whole number of them and keep that snapping.
        let deltaPixels = delta * scale
        if (deltaPixels.rounded() - deltaPixels).magnitude < 1e-6 {
          setRowOffset(Float(delta), forSlot: carried.slot, in: &scene)
          append(carried, to: &scene)
          cachedRows[rowDrawRun.id] = carried
          return
        }
      }

      let built = buildRow(
        rowDrawRun: rowDrawRun,
        rowOrigin: rowOrigin,
        rowOriginY: rowOriginY,
        slot: carried?.slot ?? takeSlot(),
        columns: boundingRect.columns,
        snapshot: snapshot,
        glyphAtlas: glyphAtlas,
        scale: scale,
      )
      setRowOffset(0, forSlot: built.slot, in: &scene)
      append(built, to: &scene)
      cachedRows[rowDrawRun.id] = built
    }

    if
      snapshot.cursorBlinkingPhase,
      // Hidden while Neovim is busy, as busy_start asks. Not tied to the
      // mouse: 'mouse' being off says nothing about the cursor.
      !snapshot.isBusy,
      let cursorDrawRun = snapshot.grid.drawRuns.cursorDrawRun,
      boundingRect.contains(cursorDrawRun.origin)
    {
      appendCursorInstances(
        cursorDrawRun,
        snapshot: snapshot,
        glyphAtlas: glyphAtlas,
        scale: scale,
        to: &scene,
      )
    }

    previousSceneCounts = .init(scene: scene)
    return scene
  }

  /// Turns one row into instances, in the coordinates given by `rowOrigin`.
  /// This is the work the cache exists to skip.
  private func buildRow(
    rowDrawRun: RowDrawRun,
    rowOrigin: CGPoint,
    rowOriginY: CGFloat,
    slot: Int,
    columns: Range<Int>,
    snapshot: GridDrawSnapshot,
    glyphAtlas: GridMetalGlyphAtlas,
    scale: CGFloat,
  )
  -> CachedRow {
    var row = CachedRow(slot: slot, originY: rowOriginY)

    rowDrawRun.forEachVisibleDrawRun(
      columnsRange: columns,
      at: rowOrigin,
      font: snapshot.font,
      upsideDownTransform: snapshot.upsideDownTransform,
    ) { drawRun, rect in
      row.backgroundQuads.append(
        quadInstance(
          rect: rect,
          color: snapshot.appearance.backgroundColor(for: drawRun.highlightID).metal,
          rowSlot: slot,
        ),
      )

      appendDecorationInstances(
        for: drawRun,
        rect: rect,
        font: snapshot.font,
        appearance: snapshot.appearance,
        scale: scale,
        rowSlot: slot,
        to: &row.decorationQuads,
      )

      if let glyphRuns = drawRun.glyphRuns {
        appendGlyphInstances(
          glyphRuns,
          in: rect,
          color: snapshot.appearance.foregroundColor(for: drawRun.highlightID).metal,
          glyphAtlas: glyphAtlas,
          scale: scale,
          rowSlot: slot,
          to: &row.glyphInstances,
        )
      }
    }

    return row
  }

  /// Copies a row's instances into the scene. Always a bulk append: a row that
  /// moved is handled by its slot offset, never by rewriting its instances.
  private func append(_ row: CachedRow, to scene: inout GridMetalScene) {
    scene.backgroundQuads.append(contentsOf: row.backgroundQuads)
    scene.decorationQuads.append(contentsOf: row.decorationQuads)
    scene.glyphInstances.append(contentsOf: row.glyphInstances)
  }

  private func setRowOffset(_ offset: Float, forSlot slot: Int, in scene: inout GridMetalScene) {
    if scene.rowOffsets.count <= slot {
      scene.rowOffsets.append(contentsOf: repeatElement(0, count: slot + 1 - scene.rowOffsets.count))
    }
    scene.rowOffsets[slot] = offset
  }

  private func appendGlyphInstances(
    _ glyphRuns: [GlyphRun],
    in rect: CGRect,
    color: SIMD4<Float>,
    glyphAtlas: GridMetalGlyphAtlas,
    scale: CGFloat,
    rowSlot: Int,
    clipRect: CGRect? = nil,
    to glyphInstances: inout [GridMetalGlyphInstance],
  ) {
    for glyphRun in glyphRuns {
      for index in glyphRun.glyphs.indices {
        guard let entry = glyphAtlas.entry(for: glyphRun.glyphs[index], font: glyphRun.appKitFont) else {
          continue
        }

        // Snapped to whole device pixels, so the quad covers exactly as many
        // pixels as the bitmap has texels and the sampler does not resample.
        let glyphRect = CGRect(
          x: ((rect.origin.x + glyphRun.positions[index].x + CGFloat(entry.origin.x)) * scale)
            .rounded() / scale,
          y: ((rect.origin.y + glyphRun.positions[index].y + CGFloat(entry.origin.y)) * scale)
            .rounded() / scale,
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
            rowSlot: rowSlot,
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
              rowSlot: Float(rowSlot),
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
    scale: CGFloat,
    to scene: inout GridMetalScene,
  ) {
    let (cursorForegroundColor, cursorBackgroundColor) = cursorDrawRun
      .colors(with: snapshot.appearance)

    let offset = cursorDrawRun.origin * snapshot.font.cellSize
    let cursorRect = cursorDrawRun.cellFrame
      .offsetBy(dx: offset.x, dy: offset.y)
      .applying(snapshot.upsideDownTransform)

    let isHollow = !snapshot.isApplicationActive && cursorDrawRun.isHollowWhenInactive

    // Slot zero: the cursor belongs to no row and never needs re-basing.
    let cursorRects = isHollow
      ? cursorDrawRun.outlineRects(of: cursorRect, thickness: 1 / max(scale, 1))
      : [cursorRect]
    for rect in cursorRects {
      scene.cursorQuads.append(
        quadInstance(rect: rect, color: cursorBackgroundColor.metal, rowSlot: 0),
      )
    }

    // A hollow cursor leaves the row's own text showing through, so there is
    // nothing to redraw in the swapped colour.
    if
      !isHollow,
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
        scale: scale,
        rowSlot: 0,
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
    rowSlot: Int,
    to quads: inout [GridMetalQuadInstance],
  ) {
    guard case let .text(_, cellsCount, _) = drawRun.rowPartContent else {
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
          rowSlot: rowSlot,
        ),
      )
    }

    if decorations.isUnderline {
      quads.append(
        quadInstance(
          rect: .init(x: rect.minX, y: underlineY, width: rect.width, height: thickness),
          color: color,
          rowSlot: rowSlot,
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
        rowSlot: rowSlot,
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
        rowSlot: rowSlot,
        to: &quads,
      )
    } else if decorations.isUnderdouble {
      quads.append(
        quadInstance(
          rect: .init(x: rect.minX, y: underlineY, width: rect.width, height: thickness),
          color: color,
          rowSlot: rowSlot,
        ),
      )
      quads.append(
        quadInstance(
          rect: .init(x: rect.minX, y: underlineY + 3, width: rect.width, height: thickness),
          color: color,
          rowSlot: rowSlot,
        ),
      )
    } else if decorations.isUndercurl {
      let widthDivider = 3
      let xStep = font.cellWidth / Double(widthDivider)
      let pointsCount = cellsCount * widthDivider + 1
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
            rowSlot: rowSlot,
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
    rowSlot: Int,
    to quads: inout [GridMetalQuadInstance],
  ) {
    var currentX = fromX
    while currentX < toX {
      let width = min(segmentWidth, toX - currentX)
      quads.append(
        quadInstance(
          rect: .init(x: currentX, y: y, width: width, height: thickness),
          color: color,
          rowSlot: rowSlot,
        ),
      )
      currentX += segmentWidth + gapWidth
    }
  }

  private func quadInstance(
    rect: CGRect,
    color: SIMD4<Float>,
    rowSlot: Int,
  )
  -> GridMetalQuadInstance {
    .init(
      origin: .init(Float(rect.origin.x), Float(rect.origin.y)),
      size: .init(Float(rect.width), Float(rect.height)),
      color: color,
      rowSlot: Float(rowSlot),
    )
  }

  private func clippedGlyphInstance(
    rect: CGRect,
    uvOrigin: SIMD2<Float>,
    uvSize: SIMD2<Float>,
    color: SIMD4<Float>,
    rowSlot: Int,
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
      rowSlot: Float(rowSlot),
    )
  }
}

nonisolated extension Color {
  /// Built straight from the stored components, with no NSColor round trip.
  /// Called for every quad and every glyph instance.
  var metal: SIMD4<Float> {
    .init(Float(red), Float(green), Float(blue), Float(alpha))
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
