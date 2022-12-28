// SPDX-License-Identifier: MIT

import AppKit
import CasePaths
import ComposableArchitecture
import IdentifiedCollections
import Library
import MessagePack
import Neovim
import Overture
import Tagged

public enum Action: Sendable {
  case createProcess(keyPresses: AsyncStream<KeyPress>)
  case bindProcess(Neovim.Process, keyPresses: AsyncStream<KeyPress>)
  case setFont(State.Font)
  case applyDefaultColorsSet([UIEvents.DefaultColorsSet])
  case applyHlAttrDefine([UIEvents.HlAttrDefine])
  case applyGridResizeUIEvents([UIEvents.GridResize])
  case applyGridLineUIEvents([UIEvents.GridLine])
  case applyGridScrollUIEvents([UIEvents.GridScroll])
  case applyGridClearUIEvents([UIEvents.GridClear])
  case applyGridDestroyUIEvents([UIEvents.GridDestroy])
  case applyGridCursorGotoUIEvents([UIEvents.GridCursorGoto])
  case applyWinPosUIEvents([UIEvents.WinPos])
  case applyWinFloatPosUIEvents([UIEvents.WinFloatPos])
  case applyWinHideUIEvents([UIEvents.WinHide])
  case applyWinCloseUIEvents([UIEvents.WinClose])
  case flush
  case handleError(Error)
  case processFinished(error: Error?)
}

public struct Reducer: ReducerProtocol {
  public init() {}

  public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case let .createProcess(keyPresses):
      let process = Neovim.Process()

      return .run { send in
        do {
          for try await state in await process.states {
            switch state {
            case .running:
              await send(.bindProcess(process, keyPresses: keyPresses))
            }
          }

          await send(.processFinished(error: nil))

        } catch {
          await send(.processFinished(error: error))
        }
      }
      .concatenate(with: .cancel(id: EffectID.bindProcess))

    case let .bindProcess(process, keyPresses):
      let applyUIEventBatches = EffectTask<Action>.run { send in
        var isFirstFlush = true

        for await uiEventBatch in await process.api.uiEventBatches {
          guard !Task.isCancelled else {
            break
          }

          do {
            switch uiEventBatch {
            case let .defaultColorsSet(decode):
              await send(.applyDefaultColorsSet(try decode()))

            case let .hlAttrDefine(decode):
              await send(.applyHlAttrDefine(try decode()))

            case let .gridResize(decode):
              await send(.applyGridResizeUIEvents(try decode()))

            case let .gridLine(decode):
              await send(.applyGridLineUIEvents(try decode()))

            case let .gridScroll(decode):
              await send(.applyGridScrollUIEvents(try decode()))

            case let .gridClear(decode):
              await send(.applyGridClearUIEvents(try decode()))

            case let .gridDestroy(decode):
              await send(.applyGridDestroyUIEvents(try decode()))

            case let .gridCursorGoto(decode):
              await send(.applyGridCursorGotoUIEvents(try decode()))

            case let .winPos(decode):
              await send(.applyWinPosUIEvents(try decode()))

            case let .winFloatPos(decode):
              await send(.applyWinFloatPosUIEvents(try decode()))

            case let .winHide(decode):
              await send(.applyWinHideUIEvents(try decode()))

            case let .winClose(decode):
              await send(.applyWinCloseUIEvents(try decode()))

            case .flush:
              if isFirstFlush {
                await send(
                  .setFont(
                    .init(.init(name: "MesloLGS Nerd Font", size: 13)!)
                  )
                )
              }

              await send(.flush)

              isFirstFlush = false

            default:
              break
            }

          } catch {
            await send(.handleError(error))
          }
        }
      }

      let reportKeyPresses = EffectTask<Action>.run { send in
        for await keyPress in keyPresses {
          guard !Task.isCancelled else {
            break
          }

          do {
            _ = try await process.api.nvimInput(
              keys: keyPress.makeNvimKeyCode()
            )
            .get()

          } catch {
            await send(.handleError(error))
          }
        }
      }

      let requestUIAttach = EffectTask<Action>.run { send in
        do {
          _ = try await process.api.nvimUIAttach(
            width: 140,
            height: 60,
            options: [
              "ext_multigrid": true,
              "ext_hlstate": true,
              // "ext_cmdline": false,
              // "ext_messages": true,
              // "ext_popupmenu": true,
              // "ext_tabline": true,
            ]
          )
          .get()

        } catch {
          await send(.handleError(error))
        }
      }

      return .merge(
        applyUIEventBatches,
        reportKeyPresses,
        requestUIAttach
      )
      .cancellable(id: EffectID.bindProcess)

    case let .setFont(font):
      state.current.font = font
      return .none

    case let .applyDefaultColorsSet(uiEvents):
      for uiEvent in uiEvents {
        state.current.highlights
          .updateOrAppend(
            .init(
              id: .default,
              foregroundColor: .init(rgb: uiEvent.rgbFg),
              backgroundColor: .init(rgb: uiEvent.rgbBg),
              specialColor: .init(rgb: uiEvent.rgbSp)
            )
          )
      }
      return .none

    case let .applyHlAttrDefine(uiEvents):
      for uiEvent in uiEvents {
        let id = State.Highlight.ID(rawValue: uiEvent.id)

        update(&state.current.highlights[id: id]) { highlight in
          if highlight == nil {
            highlight = .init(id: id)
          }

          for (key, value) in uiEvent.rgbAttrs {
            guard case let .string(key) = key else {
              continue
            }

            switch key {
            case "foreground":
              if case let .integer(value) = value {
                highlight!.foregroundColor = .init(rgb: value)
              }

            case "background":
              if case let .integer(value) = value {
                highlight!.backgroundColor = .init(rgb: value)
              }

            case "special": if case let .integer(value) = value {
                highlight!.specialColor = .init(rgb: value)
              }

            case "bold": if case let .boolean(value) = value {
                highlight!.isBold = value
              }

            case "italic": if case let .boolean(value) = value {
                highlight!.isItalic = value
              }

            default:
              break
            }
          }
        }
      }
      return .none

    case let .applyGridResizeUIEvents(uiEvents):
      for uiEvent in uiEvents {
        let id = State.Grid.ID(rawValue: uiEvent.grid)
        let size = IntegerSize(
          columnsCount: uiEvent.width,
          rowsCount: uiEvent.height
        )

        update(&state.current.grids[id: id]) { grid in
          let cells = TwoDimensionalArray<State.Cell>(
            size: size,
            elementAtPoint: { point in
              guard
                let grid,
                point.row < grid.cells.rowsCount,
                point.column < grid.cells.columnsCount
              else {
                return .default
              }

              let rows = grid.cells.rows
              let row = rows[rows.startIndex + point.row]
              return row[row.startIndex + point.column]
            }
          )

          grid = .init(
            id: id,
            cells: cells,
            rowHighlightChunks: cells.rows
              .map { $0.makeHighlightChunks() }
          )
        }
      }
      return .none

    case let .applyGridLineUIEvents(uiEvents):
      do {
        for uiEvent in uiEvents {
          try updateLine(
            in: &state.current.grids[id: .init(uiEvent.grid)]!,
            origin: .init(column: uiEvent.colStart, row: uiEvent.row),
            values: uiEvent.data
          )
        }
        return .none

      } catch {
        return .task { .handleError(error) }
      }

    case let .applyGridScrollUIEvents(uiEvents):
      for uiEvent in uiEvents {
        let gridID = State.Grid.ID(rawValue: uiEvent.grid)
        update(&state.current.grids[id: gridID]!) { grid in
          let gridCopy = grid

          for fromRow in uiEvent.top ..< uiEvent.bot {
            let toRow = fromRow - uiEvent.rows

            guard toRow >= 0, toRow < grid.cells.rowsCount else {
              continue
            }

            grid.cells.rows[toRow] = gridCopy.cells.rows[fromRow]
            grid.rowHighlightChunks[toRow] = gridCopy.rowHighlightChunks[fromRow]
          }
        }
      }
      return .none

    case let .applyGridClearUIEvents(uiEvents):
      for uiEvent in uiEvents {
        let gridID = State.Grid.ID(rawValue: uiEvent.grid)

        update(&state.current.grids[id: gridID]!) { grid in
          let rowCells = ArraySlice(
            repeating: State.Cell.default,
            count: grid.cells.columnsCount
          )
          let highlightChunks = rowCells.makeHighlightChunks()

          for row in grid.cells.rows.indices {
            grid.cells.rows[row] = rowCells
            grid.rowHighlightChunks[row] = highlightChunks
          }
        }
      }
      return .none

    case let .applyGridDestroyUIEvents(uiEvents):
      for uiEvent in uiEvents {
        let gridID = State.Grid.ID(rawValue: uiEvent.grid)

        state.current.windows.removeAll(where: { $0.gridID == gridID })
        state.current.floatingWindows.removeAll(where: { $0.gridID == gridID })
      }
      return .none

    case let .applyGridCursorGotoUIEvents(uiEvents):
      for uiEvent in uiEvents {
        state.current.cursor = .init(
          gridID: .init(uiEvent.grid),
          position: .init(
            column: uiEvent.col,
            row: uiEvent.row
          )
        )
      }
      return .none

    case let .applyWinPosUIEvents(uiEvents):
      for uiEvent in uiEvents {
        state.current.floatingWindows.remove(id: uiEvent.win)

        let zIndex = state.nextWindowZIndex()
        update(&state.current.windows[id: uiEvent.win]) { window in
          window = .init(
            reference: uiEvent.win,
            gridID: .init(uiEvent.grid),
            frame: .init(
              origin: .init(
                column: uiEvent.startcol,
                row: uiEvent.startrow
              ),
              size: .init(
                columnsCount: uiEvent.width,
                rowsCount: uiEvent.height
              )
            ),
            zIndex: zIndex,
            isHidden: false
          )
        }
      }

      return .none

    case let .applyWinFloatPosUIEvents(uiEvents):
      for uiEvent in uiEvents {
        state.current.windows.remove(id: uiEvent.win)

        update(&state.current.floatingWindows[id: uiEvent.win]) { floatingWindow in
          floatingWindow = .init(
            reference: uiEvent.win,
            gridID: .init(uiEvent.grid),
            anchor: uiEvent.anchor,
            anchorGridID: .init(uiEvent.anchorGrid),
            anchorRow: uiEvent.anchorRow,
            anchorColumn: uiEvent.anchorCol,
            isFocusable: uiEvent.focusable,
            zIndex: uiEvent.zindex,
            isHidden: false
          )
        }
      }
      return .none

    case let .applyWinHideUIEvents(uiEvents):
      for uiEvent in uiEvents {
        let gridID = State.Grid.ID(rawValue: uiEvent.grid)

        for index in state.current.windows.indices {
          if state.current.windows[index].gridID == gridID {
            state.current.windows[index].isHidden = true
          }
        }

        for index in state.current.floatingWindows.indices {
          if state.current.floatingWindows[index].gridID == gridID {
            state.current.floatingWindows[index].isHidden = true
          }
        }
      }
      return .none

    case let .applyWinCloseUIEvents(uiEvents):
      for uiEvent in uiEvents {
        let gridID = State.Grid.ID(rawValue: uiEvent.grid)

        state.current.windows.removeAll(where: { $0.gridID == gridID })
        state.current.floatingWindows.removeAll(where: { $0.gridID == gridID })
      }
      return .none

    case .flush:
      state.flushed = state.current
      return .none

    default:
      return .none
    }
  }

  private struct FailedDecodingCells: Error {
    var rawValue: Value
    var details: String
  }

  private enum EffectID: String, Hashable {
    case bindProcess
  }

  private func updateLine(in grid: inout State.Grid, origin: IntegerPoint, values: [Value]) throws {
    try update(&grid.cells.rows[origin.row]) { rowCells in
      var updatedCellsCount = 0
      var highlightID = State.Highlight.ID.default

      for value in values {
        guard
          let arrayValue = (/Value.array).extract(from: value),
          !arrayValue.isEmpty,
          let text = (/Value.string).extract(from: arrayValue[0])
        else {
          throw FailedDecodingCells(
            rawValue: value,
            details: "Raw value is not an array or first element is not a text"
          )
        }

        var repeatCount = 1

        if arrayValue.count > 1 {
          guard
            let newHighlightID = (/Value.integer).extract(from: arrayValue[1])
          else {
            throw FailedDecodingCells(
              rawValue: value,
              details: "Second array element is not an integer highlight id"
            )
          }

          highlightID = .init(rawValue: newHighlightID)

          if arrayValue.count > 2 {
            guard
              let newRepeatCount = (/Value.integer).extract(from: arrayValue[2])
            else {
              throw FailedDecodingCells(
                rawValue: value,
                details: "Third array element is not a integer repeat count"
              )
            }

            repeatCount = newRepeatCount
          }
        }

        for _ in 0 ..< repeatCount {
          let cell = State.Cell(
            text: text,
            highlightID: highlightID
          )

          let index = rowCells.index(
            rowCells.startIndex,
            offsetBy: origin.column + updatedCellsCount
          )
          rowCells[index] = cell

          updatedCellsCount += 1
        }
      }
    }

    grid.rowHighlightChunks[origin.row] = grid.cells.rows[origin.row].makeHighlightChunks()
  }
}
