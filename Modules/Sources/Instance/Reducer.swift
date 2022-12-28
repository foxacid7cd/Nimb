//
//  Reducer.swift
//
//
//  Created by Yevhenii Matviienko on 28.12.2022.
//

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
  case startProcess
  case applyUIEventBatches(AsyncStream<UIEventBatch>)
  case applyGridResizeUIEvents([UIEvents.GridResize])
  case applyGridLineUIEvents([UIEvents.GridLine])
  case setFont(Font)
  case handleError(Error)
  case processFinished(error: Error?)
}

public struct Reducer: ReducerProtocol {
  public init() {}

  public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .startProcess:
      return .run { send in
        let process = Neovim.Process()

        for try await state in await process.states {
          switch state {
          case .running:
            await send(
              .setFont(
                .init(
                  .init(name: "MesloLGS NF", size: 13)!)))

            await send(
              .applyUIEventBatches(
                await process.api.uiEventBatches))

            do {
              _ = try await process.api.nvimUiAttach(
                width: 110,
                height: 36,
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
        }

        await send(.processFinished(error: nil))

      } catch: { error, send in
        await send(.processFinished(error: error))
      }

    case let .applyUIEventBatches(value):
      return .run { send in
        do {
          for await uiEventBatch in value {
            switch uiEventBatch {
            case let .gridResize(decode):
              await send(.applyGridResizeUIEvents(try decode()))

            case let .gridLine(decode):
              await send(.applyGridLineUIEvents(try decode()))

            case .flush:
              break

            default:
              break
            }
          }

        } catch {
          await send(.handleError(error))
        }
      }

    case let .applyGridResizeUIEvents(uiEvents):
      for uiEvent in uiEvents {
        let id = State.Grid.ID(rawValue: uiEvent.grid)
        let size = IntegerSize(
          columnsCount: uiEvent.width,
          rowsCount: uiEvent.height)

        update(&state.grids[id: id]) { grid in
          grid = .init(
            id: id,
            cells: .init(
              size: size,
              repeatingElement: .init(text: " ", highlightID: .default)))
        }

        if id.isOuter {
          state.outerGridSize = size
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

        for _ in 0..<repeatCount {
          let cell = Cell(
            text: text,
            highlightID: highlightID)

          let index = rowCells.index(
            rowCells.startIndex,
            offsetBy: origin.column + updatedCellsCount)
          rowCells[index] = cell

          updatedCellsCount += 1
        }
      }
    }
  }
}
