// SPDX-License-Identifier: MIT

import CasePaths
import Collections
import ComposableArchitecture
import IdentifiedCollections
import Library
import Neovim
import Overture
import SwiftUI

@MainActor
public struct InstanceView: View {
  public init(
    font: Font,
    defaultForegroundColor: Color,
    defaultBackgroundColor: Color,
    defaultSpecialColor: Color,
    outerGridSize: IntegerSize,
    highlights: IdentifiedArrayOf<Highlight>,
    store: StoreOf<Instance>
  ) {
    self.font = font
    self.defaultForegroundColor = defaultForegroundColor
    self.defaultBackgroundColor = defaultBackgroundColor
    self.defaultSpecialColor = defaultSpecialColor
    self.outerGridSize = outerGridSize
    self.highlights = highlights
    self.store = store
  }

  public var font: Font
  public var defaultForegroundColor: Color
  public var defaultBackgroundColor: Color
  public var defaultSpecialColor: Color
  public var outerGridSize: IntegerSize
  public var highlights: IdentifiedArrayOf<Highlight>
  public var store: StoreOf<Instance>

  public var body: some View {
    WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: {
        $0.gridsLayoutUpdateFlag == $1.gridsLayoutUpdateFlag
      }
    ) { state in
      let outerGridSize = outerGridSize * font.cellSize
      let outerGridFrame = CGRect(origin: .init(), size: outerGridSize)

      ZStack(alignment: .topLeading) {
        GridView(
          gridID: .outer,
          font: font,
          highlights: highlights,
          defaultForegroundColor: defaultForegroundColor,
          defaultBackgroundColor: defaultBackgroundColor,
          defaultSpecialColor: defaultSpecialColor,
          store: store
        )
        .frame(width: outerGridSize.width, height: outerGridSize.height)
        .zIndex(0)

        ForEach(state.windows) { window in
          let frame = window.frame * font.cellSize
          let clippedFrame = frame.intersection(outerGridFrame)

          GridView(
            gridID: window.gridID,
            font: font,
            highlights: highlights,
            defaultForegroundColor: defaultForegroundColor,
            defaultBackgroundColor: defaultBackgroundColor,
            defaultSpecialColor: defaultSpecialColor,
            store: store
          )
          .frame(width: clippedFrame.width, height: clippedFrame.height)
          .offset(x: clippedFrame.minX, y: clippedFrame.minY)
          .zIndex(Double(window.zIndex) / 1000 + 1000)
          .opacity(window.isHidden ? 0 : 1)
        }

        ForEach(state.floatingWindows) { floatingWindow in
          let frame = calculateFrame(
            for: floatingWindow,
            grid: state.grids[id: floatingWindow.gridID]!,
            grids: state.grids,
            windows: state.windows,
            floatingWindows: state.floatingWindows,
            cellSize: font.cellSize
          )
          let clippedFrame = frame.intersection(outerGridFrame)

          GridView(
            gridID: floatingWindow.gridID,
            font: font,
            highlights: highlights,
            defaultForegroundColor: defaultForegroundColor,
            defaultBackgroundColor: defaultBackgroundColor,
            defaultSpecialColor: defaultSpecialColor,
            store: store
          )
          .frame(width: clippedFrame.width, height: clippedFrame.height)
          .offset(x: clippedFrame.minX, y: clippedFrame.minY)
          .zIndex(Double(floatingWindow.zIndex) / 1000 + 1_000_000)
          .opacity(floatingWindow.isHidden ? 0 : 1)
        }
      }
    }
  }

  private func calculateFrame(
    for floatingWindow: FloatingWindow,
    grid: Grid,
    grids: IdentifiedArrayOf<Grid>,
    windows: IdentifiedArrayOf<Window>,
    floatingWindows: IdentifiedArrayOf<FloatingWindow>,
    cellSize: CGSize
  )
    -> CGRect
  {
    let anchorGrid = grids[id: floatingWindow.anchorGridID]!

    let anchorGridOrigin: CGPoint
    if let windowID = anchorGrid.windowID {
      if let window = windows[id: windowID] {
        anchorGridOrigin = window.frame.origin * cellSize

      } else {
        let floatingWindow = floatingWindows[id: windowID]!

        anchorGridOrigin = calculateFrame(
          for: floatingWindow,
          grid: grids[id: floatingWindow.gridID]!,
          grids: grids,
          windows: windows,
          floatingWindows: floatingWindows,
          cellSize: cellSize
        )
        .origin
      }

    } else {
      anchorGridOrigin = .init()
    }

    var frame = CGRect(
      origin: .init(
        x: anchorGridOrigin.x + (floatingWindow.anchorColumn * cellSize.width),
        y: anchorGridOrigin.y + (floatingWindow.anchorRow * cellSize.height)
      ),
      size: grid.cells.size * cellSize
    )

    switch floatingWindow.anchor {
    case .northWest:
      break

    case .northEast:
      frame.origin.x -= frame.size.width

    case .southWest:
      frame.origin.y -= frame.size.height

    case .southEast:
      frame.origin.x -= frame.size.width
      frame.origin.y -= frame.size.height
    }

    return frame
  }
}

@MainActor
public struct GridView: View {
  public init(
    gridID: Grid.ID,
    font: Font,
    highlights: IdentifiedArrayOf<Highlight>,
    defaultForegroundColor: Color,
    defaultBackgroundColor: Color,
    defaultSpecialColor: Color,
    store: StoreOf<Instance>
  ) {
    self.gridID = gridID
    self.font = font
    self.highlights = highlights
    self.defaultForegroundColor = defaultForegroundColor
    self.defaultBackgroundColor = defaultBackgroundColor
    self.defaultSpecialColor = defaultSpecialColor
    self.store = store
  }

  public var gridID: Grid.ID
  public var font: Font
  public var highlights: IdentifiedArrayOf<Highlight>
  public var defaultForegroundColor: Color
  public var defaultBackgroundColor: Color
  public var defaultSpecialColor: Color
  public var store: StoreOf<Instance>

  public var body: some SwiftUI.View {
    WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: {
        $0.gridUpdateFlags[gridID] == $1.gridUpdateFlags[gridID]
      }
    ) { state in
      let grid = state.grids[id: gridID]!

      Canvas(opaque: true, colorMode: .extendedLinear) { graphicsContext, size in
        graphicsContext.fill(
          Path(CGRect(origin: .init(), size: size)),
          with: .color(defaultBackgroundColor.swiftUI),
          style: .init(antialiased: false)
        )

        var backgroundRuns = [(frame: CGRect, color: Color)]()
        var foregroundRuns = [(origin: CGPoint, text: Text)]()

        for (row, rowLayout) in zip(0 ..< grid.rowLayouts.count, grid.rowLayouts) {
          let rowFrame = CGRect(
            origin: .init(x: 0, y: Double(row) * font.cellHeight),
            size: .init(width: size.width, height: font.cellHeight)
          )

          for rowPart in rowLayout.parts {
            let frame = CGRect(
              origin: .init(
                x: Double(rowPart.indices.lowerBound) * font.cellWidth,
                y: rowFrame.origin.y
              ),
              size: .init(
                width: Double(rowPart.indices.count) * font.cellWidth,
                height: rowFrame.size.height
              )
            )

            let highlight = highlights[id: rowPart.highlightID]

            let backgroundColor = highlight?.backgroundColor ?? defaultBackgroundColor
            backgroundRuns.append((frame, backgroundColor))

            let foregroundColor = highlight?.foregroundColor ?? defaultForegroundColor

            let text = Text(rowPart.text)
              .font(.init(font.appKit))
              .foregroundColor(foregroundColor.swiftUI)
              .bold(highlight?.isBold == true)
              .italic(highlight?.isItalic == true)

            foregroundRuns.append((frame.origin, text))
          }
        }

        graphicsContext.drawLayer { backgroundGraphicsContext in
          for backgroundRun in backgroundRuns {
            backgroundGraphicsContext.fill(
              Path(backgroundRun.frame),
              with: .color(backgroundRun.color.swiftUI),
              style: .init(antialiased: false)
            )
          }
        }

        graphicsContext.drawLayer { foregroundGraphicsContext in
          for foregroundRun in foregroundRuns {
            foregroundGraphicsContext.draw(
              foregroundRun.text,
              at: foregroundRun.origin,
              anchor: .zero
            )
          }
        }

        if let cursor = state.cursor, cursor.gridID == gridID {
          graphicsContext.drawLayer { cursorGraphicsContext in
            let rowLayout = grid.rowLayouts[cursor.position.row]
            let cursorIndices = rowLayout.cellIndices[cursor.position.column]

            let integerFrame = IntegerRectangle(
              origin: .init(column: cursorIndices.startIndex, row: cursor.position.row),
              size: .init(columnsCount: cursorIndices.count, rowsCount: 1)
            )
            let frame = integerFrame * font.cellSize

            cursorGraphicsContext.fill(
              Path(frame),
              with: .color(.white)
            )

            let cell = grid.cells[cursor.position]

            let text = Text(cell.text)
              .font(.init(font.appKit))
              .foregroundColor(.black)

            cursorGraphicsContext.draw(
              text,
              at: .init(x: frame.midX, y: frame.midY)
            )
          }
        }
      }
    }
  }
}
