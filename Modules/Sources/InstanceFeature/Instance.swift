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

public struct Instance: ReducerProtocol {
  public init() {}

  public enum Action: Sendable {
    case setDefaultFont(State.Font)
    case createNeovimProcess(
      arguments: [String],
      environmentOverlay: [String: String],
      keyPresses: AsyncStream<KeyPress>,
      cursorPhases: AsyncStream<Bool>
    )
    case bindNeovimProcess(
      Neovim.Process,
      keyPresses: AsyncStream<KeyPress>,
      cursorPhases: AsyncStream<Bool>
    )
    case applyUIEventsBatch([UIEvent])
    ///    case applyOptionSetUIEvents([UIEvents.OptionSet])
    ///    case setFont(State.Font?)
    ///    case applySetTitleUIEvents([UIEvents.SetTitle])
    ///    case applyDefaultColorsSetUIEvents([UIEvents.DefaultColorsSet])
    ///    case applyHlAttrDefineUIEvents([UIEvents.HlAttrDefine])
    ///    case applyGridResizeUIEvents([UIEvents.GridResize])
    ///    case applyGridLineUIEvents([UIEvents.GridLine])
    ///    case applyGridScrollUIEvents([UIEvents.GridScroll])
    ///    case applyGridClearUIEvents([UIEvents.GridClear])
    ///    case applyGridDestroyUIEvents([UIEvents.GridDestroy])
    ///    case applyGridCursorGotoUIEvents([UIEvents.GridCursorGoto])
    ///    case applyWinPosUIEvents([UIEvents.WinPos])
    ///    case applyWinFloatPosUIEvents([UIEvents.WinFloatPos])
    ///    case applyWinHideUIEvents([UIEvents.WinHide])
    ///    case applyWinCloseUIEvents([UIEvents.WinClose])
    case setCursorPhase(Bool)
    case handleError(Error)
    case processFinished(error: Error?)
  }

  public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case let .setDefaultFont(font):
      state.defaultFont = font
      return .none

    case let .createNeovimProcess(arguments, environmentOverlay, keyPresses, cursorPhases):
      let process = Neovim.Process(
        arguments: arguments,
        environmentOverlay: environmentOverlay
      )

      return .run { send in
        do {
          for try await state in await process.states {
            switch state {
            case .running:
              await send(
                .bindNeovimProcess(
                  process,
                  keyPresses: keyPresses,
                  cursorPhases: cursorPhases
                )
              )
            }
          }

          await send(.processFinished(error: nil))

        } catch {
          await send(.processFinished(error: error))
        }
      }
      .concatenate(with: .cancel(id: EffectID.bindProcess))

    case let .bindNeovimProcess(process, keyPresses, cursorPhases):
      let applyUIEventBatches = EffectTask<Action>.run { send in
        for try await value in await process.api.uiEventBatches {
          guard !Task.isCancelled else {
            return
          }
          await send(.applyUIEventsBatch(value))
        }
      }

      let reportKeyPresses = EffectTask<Action>.run { send in
        for await keyPress in keyPresses {
          guard !Task.isCancelled else {
            return
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
          let uiOptions: UIOptions = [
            .extMultigrid,
            .extHlstate,
            .extCmdline,
            .extMessages,
            .extPopupmenu,
            .extTabline,
          ]

          _ = try await process.api.nvimUIAttach(
            width: 110,
            height: 36,
            options: uiOptions
              .nvimUIAttachOptions
          )
          .get()

        } catch {
          await send(.handleError(error))
        }
      }

      let applyCursorPhases = EffectTask<Action>.run { send in
        for await cursorPhase in cursorPhases {
          guard !Task.isCancelled else {
            return
          }

          await send(.setCursorPhase(cursorPhase))
        }
      }

      return .merge(
        applyUIEventBatches,
        reportKeyPresses,
        requestUIAttach,
        applyCursorPhases
      )
      .cancellable(id: EffectID.bindProcess)

    case let .applyUIEventsBatch(uiEventsBatch):
      state.bufferedUIEvents += uiEventsBatch

      if uiEventsBatch.last.flatMap(/UIEvent.flush) != nil {
        var uiEvents = [UIEvent]()
        swap(&uiEvents, &state.bufferedUIEvents)

        uiEvents: for uiEvent in uiEvents {
          switch uiEvent {
          case let .setTitle(title):
            state.title = title

          case let .optionSet(name, value):
            state.rawOptions.updateValue(
              value,
              forKey: name,
              insertingAt: state.rawOptions.count
            )

          case let .defaultColorsSet(rgbFg, rgbBg, rgbSp, _, _):
            state.highlights.updateOrAppend(
              .init(
                id: .default,
                foregroundColor: .init(rgb: rgbFg),
                backgroundColor: .init(rgb: rgbBg),
                specialColor: .init(rgb: rgbSp)
              )
            )

          case let .hlAttrDefine(rawID, rgbAttrs, _, _):
            let id = State.Highlight.ID(rawID)

            update(&state.highlights[id: id]) { highlight in
              if highlight == nil {
                highlight = .init(id: id)
              }

              for (key, value) in rgbAttrs {
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

                case "special":
                  if case let .integer(value) = value {
                    highlight!.specialColor = .init(rgb: value)
                  }

                case "bold":
                  if case let .boolean(value) = value {
                    highlight!.isBold = value
                  }

                case "italic":
                  if case let .boolean(value) = value {
                    highlight!.isItalic = value
                  }

                default:
                  break
                }
              }
            }

          case let .gridResize(rawID, width, height):
            let id = State.Grid.ID(rawID)
            let size = IntegerSize(
              columnsCount: width,
              rowsCount: height
            )

            update(&state.grids[id: id]) { grid in
              if grid == nil {
                let cells = TwoDimensionalArray<State.Cell>(
                  size: size,
                  repeatingElement: .default
                )

                grid = .init(
                  id: id,
                  cells: cells,
                  rowLayouts: cells.rows
                    .map(State.RowLayout.init(rowCells:)),
                  windowID: nil
                )

              } else {
                let newCells = TwoDimensionalArray<State.Cell>(
                  size: size,
                  elementAtPoint: { point in
                    guard
                      point.row < grid!.cells.rowsCount,
                      point.column < grid!.cells.columnsCount
                    else {
                      return .default
                    }

                    return grid!.cells[point]
                  }
                )

                grid!.cells = newCells
                grid!.rowLayouts = newCells.rows
                  .map(State.RowLayout.init(rowCells:))
              }
            }

            if
              let cursor = state.cursor,
              cursor.gridID == id,
              cursor.position.column >= size.columnsCount,
              cursor.position.row >= size.rowsCount
            {
              state.cursor = nil
            }

          case let .gridLine(rawID, row, startColumn, data):
            let id = State.Grid.ID(rawID)

            update(&state.grids[id: id]!.cells.rows[row]) { rowCells in
              var updatedCellsCount = 0
              var highlightID = State.Highlight.ID.default

              for value in data {
                guard
                  let arrayValue = (/Value.array).extract(from: value),
                  !arrayValue.isEmpty,
                  let text = (/Value.string).extract(from: arrayValue[0])
                else {
                  assertionFailure("Raw value is not an array or first element is not a text")
                  continue
                }

                var repeatCount = 1

                if arrayValue.count > 1 {
                  guard
                    let newHighlightID = (/Value.integer).extract(from: arrayValue[1])
                  else {
                    assertionFailure("Second array element is not an integer highlight id")
                    continue
                  }

                  highlightID = .init(rawValue: newHighlightID)

                  if arrayValue.count > 2 {
                    guard
                      let newRepeatCount = (/Value.integer).extract(from: arrayValue[2])
                    else {
                      assertionFailure("Third array element is not an integer repeat count")
                      continue
                    }

                    repeatCount = newRepeatCount
                  }
                }

                for _ in 0..<repeatCount {
                  let cell = State.Cell(
                    text: text,
                    highlightID: highlightID
                  )

                  let index = rowCells.index(
                    rowCells.startIndex,
                    offsetBy: startColumn + updatedCellsCount
                  )
                  rowCells[index] = cell

                  updatedCellsCount += 1
                }
              }
            }

            update(&state.grids[id: id]!) { grid in
              grid.rowLayouts[row] = .init(rowCells: grid.cells.rows[row])
            }

          default:
            break
          }
        }
      }

      return .none

      //    case let .setFont(font):
      //      state.current.font = font
      //      return .none
      //
      //    case let .applySetTitleUIEvents(uiEvents):
      //      for uiEvent in uiEvents {
      //        state.current.title = uiEvent.title
      //      }
      //      return .none
      //
      //    case let .applyOptionSetUIEvents(uiEvents):
      //      return .run { @MainActor send in
      //        for uiEvent in uiEvents {
      //          switch uiEvent.name {
      //          case "guifont":
      //            guard let value = (/Value.string).extract(from: uiEvent.value) else {
      //              assertionFailure()
      //              break
      //            }
      //
      //            let fontDescriptions = value
      //              .components(separatedBy: ",")
      //              .map { $0.trimmingCharacters(in: .whitespaces) }
      //
      //          loop: for fontDescription in fontDescriptions {
      //              let components = fontDescription
      //                .components(separatedBy: ":")
      //
      //              if components.count == 2 {
      //                switch components[0] {
      //                case "monospace":
      //                  send(Action.setFont(nil))
      //                  break loop
      //
      //                default:
      //                  let size = Double(components[1].dropFirst()) ?? 12
      //                  if let font = NSFont(name: components[0], size: size) {
      //                    send(Action.setFont(.init(font)))
      //                    break loop
      //                  }
      //                }
      //
      //              } else {
      //                if let font = NSFont(name: fontDescription, size: 12) {
      //                  send(Action.setFont(.init(font)))
      //                  break loop
      //                }
      //              }
      //            }
      //
      //          default:
      //            break
      //          }
      //        }
      //      }
      //
      //    case let .applyDefaultColorsSetUIEvents(uiEvents):
      //      for uiEvent in uiEvents {
      //        state.current.highlights
      //          .updateOrAppend(
      //            .init(
      //              id: .default,
      //              foregroundColor: .init(rgb: uiEvent.rgbFg),
      //              backgroundColor: .init(rgb: uiEvent.rgbBg),
      //              specialColor: .init(rgb: uiEvent.rgbSp)
      //            )
      //          )
      //      }
      //      return .none
      //
      //    case let .applyHlAttrDefineUIEvents(uiEvents):
      //      for uiEvent in uiEvents {
      //        let id = State.Highlight.ID(rawValue: uiEvent.id)
      //
      //        update(&state.current.highlights[id: id]) { highlight in
      //          if highlight == nil {
      //            highlight = .init(id: id)
      //          }
      //
      //          for (key, value) in uiEvent.rgbAttrs {
      //            guard case let .string(key) = key else {
      //              continue
      //            }
      //
      //            switch key {
      //            case "foreground":
      //              if case let .integer(value) = value {
      //                highlight!.foregroundColor = .init(rgb: value)
      //              }
      //
      //            case "background":
      //              if case let .integer(value) = value {
      //                highlight!.backgroundColor = .init(rgb: value)
      //              }
      //
      //            case "special": if case let .integer(value) = value {
      //                highlight!.specialColor = .init(rgb: value)
      //              }
      //
      //            case "bold": if case let .boolean(value) = value {
      //                highlight!.isBold = value
      //              }
      //
      //            case "italic": if case let .boolean(value) = value {
      //                highlight!.isItalic = value
      //              }
      //
      //            default:
      //              break
      //            }
      //          }
      //        }
      //      }
      //      return .none
      //
      //    case let .applyGridResizeUIEvents(uiEvents):
      //      for uiEvent in uiEvents {
      //        let id = State.Grid.ID(rawValue: uiEvent.grid)
      //        let size = IntegerSize(
      //          columnsCount: uiEvent.width,
      //          rowsCount: uiEvent.height
      //        )
      //
      //        update(&state.current.grids[id: id]) { grid in
      //          if grid == nil {
      //            let cells = TwoDimensionalArray<State.Cell>(
      //              size: size,
      //              repeatingElement: .default
      //            )
      //
      //            grid = .init(
      //              id: id,
      //              cells: cells,
      //              rowLayouts: cells.rows
      //                .map(State.RowLayout.init(rowCells:)),
      //              windowID: nil
      //            )
      //
      //          } else {
      //            let newCells = TwoDimensionalArray<State.Cell>(
      //              size: size,
      //              elementAtPoint: { point in
      //                guard
      //                  point.row < grid!.cells.rowsCount,
      //                  point.column < grid!.cells.columnsCount
      //                else {
      //                  return .default
      //                }
      //
      //                return grid!.cells[point]
      //              }
      //            )
      //
      //            grid!.cells = newCells
      //            grid!.rowLayouts = newCells.rows
      //              .map(State.RowLayout.init(rowCells:))
      //          }
      //        }
      //
      //        if
      //          let cursor = state.current.cursor,
      //          cursor.gridID == id,
      //          cursor.position.column >= size.columnsCount,
      //          cursor.position.row >= size.rowsCount
      //        {
      //          state.current.cursor = nil
      //        }
      //      }
      //      return .none
      //
      //    case let .applyGridLineUIEvents(uiEvents):
      //      do {
      //        for uiEvent in uiEvents {
      //          try updateLine(
      //            in: &state.current.grids[id: .init(uiEvent.grid)]!,
      //            origin: .init(column: uiEvent.colStart, row: uiEvent.row),
      //            values: uiEvent.data
      //          )
      //        }
      //        return .none
      //
      //      } catch {
      //        return .task { .handleError(error) }
      //      }
      //
      //    case let .applyGridScrollUIEvents(uiEvents):
      //      for uiEvent in uiEvents {
      //        let gridID = State.Grid.ID(rawValue: uiEvent.grid)
      //        update(&state.current.grids[id: gridID]!) { grid in
      //          let gridCopy = grid
      //
      //          for fromRow in uiEvent.top..<uiEvent.bot {
      //            let toRow = fromRow - uiEvent.rows
      //
      //            guard toRow >= 0, toRow < grid.cells.rowsCount else {
      //              continue
      //            }
      //
      //            grid.cells.rows[toRow] = gridCopy.cells.rows[fromRow]
      //            grid.rowLayouts[toRow] = gridCopy.rowLayouts[fromRow]
      //          }
      //        }
      //      }
      //      return .none
      //
      //    case let .applyGridClearUIEvents(uiEvents):
      //      for uiEvent in uiEvents {
      //        let gridID = State.Grid.ID(uiEvent.grid)
      //
      //        update(&state.current.grids[id: gridID]!) { grid in
      //          let newCells = TwoDimensionalArray<State.Cell>(
      //            size: grid.cells.size,
      //            repeatingElement: .default
      //          )
      //
      //          grid.cells = newCells
      //          grid.rowLayouts = newCells.rows
      //            .map(State.RowLayout.init(rowCells:))
      //        }
      //      }
      //      return .none
      //
      //    case let .applyGridDestroyUIEvents(uiEvents):
      //      for uiEvent in uiEvents {
      //        let gridID = State.Grid.ID(uiEvent.grid)
      //        guard var grid = state.current.grids[id: gridID] else {
      //          continue
      //        }
      //
      //        if let windowID = grid.windowID {
      //          let window = state.current.windows.remove(id: windowID)
      //
      //          if window == nil {
      //            state.current.floatingWindows.remove(id: windowID)
      //          }
      //
      //          grid.windowID = nil
      //          state.current.grids.updateOrAppend(grid)
      //        }
      //      }
      //      return .none
      //
      //    case let .applyGridCursorGotoUIEvents(uiEvents):
      //      for uiEvent in uiEvents {
      //        state.current.cursor = .init(
      //          gridID: .init(uiEvent.grid),
      //          position: .init(
      //            column: uiEvent.col,
      //            row: uiEvent.row
      //          )
      //        )
      //      }
      //      return .none
      //
      //    case let .applyWinPosUIEvents(uiEvents):
      //      for uiEvent in uiEvents {
      //        state.current.floatingWindows.remove(id: uiEvent.win)
      //
      //        let gridID = State.Grid.ID(uiEvent.grid)
      //
      //        state.current.windows.updateOrAppend(
      //          .init(
      //            reference: uiEvent.win,
      //            gridID: gridID,
      //            frame: .init(
      //              origin: .init(
      //                column: uiEvent.startcol,
      //                row: uiEvent.startrow
      //              ),
      //              size: .init(
      //                columnsCount: uiEvent.width,
      //                rowsCount: uiEvent.height
      //              )
      //            ),
      //            zIndex: state.nextWindowZIndex(),
      //            isHidden: false
      //          )
      //        )
      //        state.current.grids[id: gridID]!.windowID = uiEvent.win
      //      }
      //      return .none
      //
      //    case let .applyWinFloatPosUIEvents(uiEvents):
      //      for uiEvent in uiEvents {
      //        guard let anchor = State.Anchor(rawValue: uiEvent.anchor) else {
      //          assertionFailure("Invalid anchor value: \(uiEvent.anchor)")
      //          continue
      //        }
      //
      //        state.current.windows.remove(id: uiEvent.win)
      //
      //        let gridID = State.Grid.ID(uiEvent.grid)
      //
      //        state.current.floatingWindows.updateOrAppend(
      //          .init(
      //            reference: uiEvent.win,
      //            gridID: gridID,
      //            anchor: anchor,
      //            anchorGridID: .init(uiEvent.anchorGrid),
      //            anchorRow: uiEvent.anchorRow,
      //            anchorColumn: uiEvent.anchorCol,
      //            isFocusable: uiEvent.focusable,
      //            zIndex: uiEvent.zindex,
      //            isHidden: false
      //          )
      //        )
      //
      //        state.current.grids[id: gridID]!.windowID = uiEvent.win
      //      }
      //      return .none
      //
      //    case let .applyWinHideUIEvents(uiEvents):
      //      for uiEvent in uiEvents {
      //        let gridID = State.Grid.ID(uiEvent.grid)
      //
      //        if let windowID = state.current.grids[id: gridID]!.windowID {
      //          if let index = state.current.windows.index(id: windowID) {
      //            state.current.windows[index].isHidden = true
      //
      //          } else if let index = state.current.floatingWindows.index(id: windowID) {
      //            state.current.floatingWindows[index].isHidden = true
      //          }
      //        }
      //      }
      //      return .none
      //
      //    case let .applyWinCloseUIEvents(uiEvents):
      //      for uiEvent in uiEvents {
      //        let gridID = State.Grid.ID(uiEvent.grid)
      //        guard var grid = state.current.grids[id: gridID] else {
      //          continue
      //        }
      //
      //        if let windowID = grid.windowID {
      //          let window = state.current.windows.remove(id: windowID)
      //
      //          if window == nil {
      //            state.current.floatingWindows.remove(id: windowID)
      //          }
      //
      //          grid.windowID = nil
      //          state.current.grids.updateOrAppend(grid)
      //        }
      //      }
      //      return .none

    default:
      return .none
    }
  }

  private enum EffectID: String, Hashable {
    case bindProcess
  }
}