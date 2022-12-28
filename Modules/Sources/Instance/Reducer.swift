// SPDX-License-Identifier: MIT

import CasePaths
import ComposableArchitecture
import Foundation
import IdentifiedCollections
import Library
import MessagePack
import Neovim
import Overture
import Tagged

public enum Action: Sendable {
  case createProcess(keyPresses: AsyncStream<KeyPress>)
  case bindProcess(Neovim.Process, keyPresses: AsyncStream<KeyPress>)
  case applyGridResizeUIEvents([UIEvents.GridResize])
  case applyGridLineUIEvents([UIEvents.GridLine])
  case applyGridDestroyUIEvents([UIEvents.GridDestroy])
  case applyWinPosUIEvents([UIEvents.WinPos])
  case applyWinHideUIEvents([UIEvents.WinHide])
  case applyWinCloseUIEvents([UIEvents.WinClose])
  case setFont(Font)
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
            case let .gridResize(decode):
              await send(.applyGridResizeUIEvents(try decode()))

            case let .gridLine(decode):
              await send(.applyGridLineUIEvents(try decode()))

            case let .gridDestroy(decode):
              await send(.applyGridDestroyUIEvents(try decode()))

            case let .winPos(decode):
              await send(.applyWinPosUIEvents(try decode()))

            case let .winHide(decode):
              await send(.applyWinHideUIEvents(try decode()))

            case let .winClose(decode):
              await send(.applyWinCloseUIEvents(try decode()))

            case .flush:
              if isFirstFlush {
                await send(
                  .setFont(
                    .init(
                      .init(name: "MesloLGS Nerd Font Mono", size: 13)!
                    )
                  )
                )
              }

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
            width: 130,
            height: 40,
            options: [
              "ext_multigrid": true,
              "ext_hlstate": true,
              "ext_cmdline": false,
              "ext_messages": true,
              "ext_popupmenu": true,
              "ext_tabline": true,
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

    case let .applyGridResizeUIEvents(uiEvents):
      for uiEvent in uiEvents {
        let id = State.Grid.ID(rawValue: uiEvent.grid)
        let size = IntegerSize(
          columnsCount: uiEvent.width,
          rowsCount: uiEvent.height
        )

        update(&state.grids[id: id]) { grid in
          grid = .init(
            id: id,
            cells: .init(
              size: size,
              repeatingElement: .init(text: " ", highlightID: .default)
            )
          )
        }
      }
      return .none

    case let .applyGridLineUIEvents(uiEvents):
      do {
        for uiEvent in uiEvents {
          try updateLine(
            in: &state.grids[id: .init(uiEvent.grid)]!,
            origin: .init(column: uiEvent.colStart, row: uiEvent.row),
            values: uiEvent.data
          )
        }
        return .none

      } catch {
        return .run { send in
          await send(.handleError(error))
        }
      }

    case let .applyGridDestroyUIEvents(uiEvents):
      for uiEvent in uiEvents {
        let gridID = State.Grid.ID(rawValue: uiEvent.grid)
        if let index = state.windows.firstIndex(where: { gridID == $0.gridID }) {
          state.windows.remove(at: index)
        }
      }
      return .none

    case let .applyWinPosUIEvents(uiEvents):
      for uiEvent in uiEvents {
        state.windows.remove(id: uiEvent.win)

        update(&state.windows[id: uiEvent.win]) { window in
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
            isHidden: false
          )
        }
      }
      return .none

    case let .applyWinHideUIEvents(uiEvents):
      for uiEvent in uiEvents {
        let gridID = State.Grid.ID(rawValue: uiEvent.grid)
        let index = state.windows.firstIndex(where: { gridID == $0.gridID })!
        state.windows[index].isHidden = true
      }
      return .none

    case let .applyWinCloseUIEvents(uiEvents):
      for uiEvent in uiEvents {
        let gridID = State.Grid.ID(rawValue: uiEvent.grid)
        if let index = state.windows.firstIndex(where: { gridID == $0.gridID }) {
          state.windows.remove(at: index)
        }
      }
      return .none

    case let .setFont(font):
      state.font = font
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
      var highlightID = Highlight.ID.default

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
          let cell = Cell(
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
  }
}
