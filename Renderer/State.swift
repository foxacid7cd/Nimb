// SPDX-License-Identifier: MIT

import Overture

public struct State: Sendable {
  public struct Updates: Sendable {
    public var isAppearanceChanged: Bool = false
    public var gridUpdates: IntKeyedDictionary<Grid.UpdateResult> = [:]
    public var destroyedGridIDs: Set<Grid.ID> = []
  }

  public var appearance: Appearance = .init()
  public var font: Font
  public var highlights: IntKeyedDictionary<Highlight> = [:]
  public var defaultForegroundColor: Color = .black
  public var defaultBackgroundColor: Color = .black
  public var defaultSpecialColor: Color = .black
  public var options: [String: Value] = [:]
  public var grids: IntKeyedDictionary<Grid> = [:]

  public var outerGrid: Grid? {
    grids[Grid.OuterID]
  }

  public mutating func apply(_ uiEvents: [UIEvent], sharedDrawRunsCache: SharedDrawRunsCache, handleError: (any Error) -> Void) -> Updates {
    var updates = Updates()

    func apply(update: Grid.Update, toGridWithID gridID: Grid.ID) {
      let font = font
      let appearance = appearance
      let outerGrid = outerGrid
      Overture.update(&grids[gridID]) { grid in
        if grid == nil {
          grid = Grid(
            id: gridID,
            size: outerGrid!.size,
            font: font,
            appearance: appearance,
            sharedCache: sharedDrawRunsCache
          )
        }
      }
      let result = grids[gridID]!.apply(
        update: update,
        font: font,
        appearance: appearance,
        sharedCache: sharedDrawRunsCache
      )
      if let result {
        Overture.update(&updates.gridUpdates[gridID]) { gridUpdate in
          if gridUpdate == nil {
            gridUpdate = .dirtyRectangles([])
          }
          gridUpdate!.formUnion(result)
        }
      }
    }

    for uiEvent in uiEvents {
      switch uiEvent {
      case let .optionSet(name, value):
        options[name] = value
        updates.isAppearanceChanged = true

      case let .gridLine(gridID, row, originColumn, data, _):
        do {
          var cells = [Cell]()
          var highlightID = 0

          for value in data {
            guard
              case let .array(arrayValue) = value,
              !arrayValue.isEmpty,
              case let .string(text) = arrayValue[0]
            else {
              throw Failure("invalid grid line cell value", value)
            }

            var repeatCount = 1

            if arrayValue.count > 1 {
              guard
                case let .integer(newHighlightID) = arrayValue[1]
              else {
                throw Failure(
                  "invalid grid line cell highlight value",
                  arrayValue[1]
                )
              }

              highlightID = newHighlightID

              if arrayValue.count > 2 {
                guard
                  case let .integer(newRepeatCount) = arrayValue[2]
                else {
                  throw Failure(
                    "invalid grid line cell repeat count value",
                    arrayValue[2]
                  )
                }

                repeatCount = newRepeatCount
              }
            }

            let cell = Cell(text: text, highlightID: highlightID)
            for _ in 0 ..< repeatCount {
              cells.append(cell)
            }
          }

          let lineUpdatesResult = grids[gridID]!
            .applying(
              lineUpdates: [(originColumn, cells)],
              forRow: row,
              font: font,
              appearance: appearance,
              sharedCache: sharedDrawRunsCache
            )

          update(&grids[gridID]!) { grid in
            grid.layout.cells.rows[row] = lineUpdatesResult.rowCells
            grid.layout.rowLayouts[row] = lineUpdatesResult.rowLayout
            grid.drawRuns.rowDrawRuns[row] = lineUpdatesResult.rowDrawRun

            if lineUpdatesResult.shouldUpdateCursorDrawRun {
              grid.drawRuns.cursorDrawRun!.updateParent(
                with: grid.layout,
                rowDrawRuns: grid.drawRuns.rowDrawRuns
              )
            }
          }

          update(&updates.gridUpdates[gridID]) { updates in
            let dirtyRectangles = lineUpdatesResult.dirtyRectangles

            switch updates {
            case var .dirtyRectangles(accumulator):
              accumulator += dirtyRectangles
              updates = .dirtyRectangles(accumulator)

            case .none:
              updates = .dirtyRectangles(dirtyRectangles)

            default:
              break
            }
          }

        } catch {
          handleError(error)
        }

      case let .gridResize(gridID, width, height):
        let size = IntegerSize(
          columnsCount: width,
          rowsCount: height
        )
        if
          grids[gridID]?.size != size
        {
          update(&grids[gridID]) { [font, appearance] grid in
            if grid == nil {
              let cells = TwoDimensionalArray(
                size: size,
                repeatingElement: Cell.default
              )
              let layout = GridLayout(cells: cells)
              grid = .init(
                id: gridID,
                layout: layout,
                drawRuns: .init(
                  layout: layout,
                  font: font,
                  appearance: appearance,
                  sharedCache: sharedDrawRunsCache
                )
              )
            }
          }

          apply(update: .resize(size), toGridWithID: gridID)
        }

      case let .gridScroll(
        gridID,
        top,
        bottom,
        left,
        right,
        rowsCount,
        columnsCount
      ):
        let rectangle = IntegerRectangle(
          origin: .init(column: left, row: top),
          size: .init(columnsCount: right - left, rowsCount: bottom - top)
        )
        let offset = IntegerSize(
          columnsCount: columnsCount,
          rowsCount: rowsCount
        )

        apply(
          update: .scroll(rectangle: rectangle, offset: offset),
          toGridWithID: gridID
        )

      case let .gridClear(gridID):
        apply(update: .clear, toGridWithID: gridID)

      case let .gridDestroy(gridID):
        update(&grids[gridID]) { grid in
          guard grid != nil else {
            return
          }
          grid = nil
          updates.destroyedGridIDs.insert(gridID)
        }

      default:
        break
      }
    }
    return updates
  }
}
