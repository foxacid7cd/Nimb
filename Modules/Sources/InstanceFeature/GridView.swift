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

      Canvas(opaque: true, colorMode: .extendedLinear, rendersAsynchronously: true) { graphicsContext, size in
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
