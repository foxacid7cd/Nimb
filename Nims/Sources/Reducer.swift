//
//  Reducer.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 16.12.2022.
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
  case runInstance
  case applyUIEventBatches(AsyncStream<UIEventBatch>)
  case setInitialInstanceState(State.Instance)
  case removeInstanceState
  //  case setFont(Font)
  //  case setDefaultBackgroundColor(Color)
  //  case appendUIEventBatch(UIEventBatch)
}

public struct Reducer: ReducerProtocol {
  public init() {}

  public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .runInstance:
      return .run { send in
        let instance = Neovim.Process()

        for try await state in await instance.states {
          switch state {
          case .running:
            await send(
              .applyUIEventBatches(
                await instance.api.uiEventBatches))
          }
        }

        await send(.removeInstanceState)

      } catch: { _, _ in
      }

    case let .applyUIEventBatches(value):
      return .run { send in
        for await uiEventBatch in value {
          switch uiEventBatch {
          case .flush:
            break

          default:
            break
          }
        }
      }

    case let .setInitialInstanceState(value):
      state.instance = value
      return .none

    case .removeInstanceState:
      state.instance = nil
      return .none
    }
    //    switch action {
    //    case let .setFont(font):
    //      state.font = font
    //      return .none
    //
    //    case let .appendUIEventBatch(batch):
    //      do {
    //        switch batch {
    //        case let .gridResize(decode):
    //          for event in try decode() {
    //            let id = Grid.ID(event.grid)
    //
    //            update(&state.grids[id: .init(event.grid)]) { grid in
    //              if grid == nil {
    //                grid = .init(
    //                  id: id,
    //                  cells: .init(
    //                    size: .init(columnsCount: event.width, rowsCount: event.height),
    //                    repeatingElement: .init(text: " ", highlightID: .default)
    //                  )
    //                )
    //
    //              } else {
    //                fatalError()
    //              }
    //            }
    //          }
    //          return .none
    //
    //        case let .gridLine(decode):
    //          for event in try decode() {
    //            let id = Grid.ID(event.grid)
    //
    //            try update(&state.grids[id: id]!) { grid in
    //              try grid.applyGridLineUpdate(
    //                row: event.row,
    //                startColumn: event.colStart,
    //                values: event.data
    //              )
    //            }
    //          }
    //          return .none
    //
    //        default:
    //          return .none
    //        }
    //
    //      } catch {
    //        os_log("Reduce failed with error (\(error))")
    //
    //        return .none
    //      }
    //
    //    case .setDefaultBackgroundColor(_):
    //      return .none
    //    }
  }
}

extension State.Grid {
  fileprivate struct FailedDecodingCells: Error {
    var rawValue: Value
    var details: String
  }

  fileprivate mutating func applyGridLineUpdate(row: Int, startColumn: Int, values: [Value]) throws
  {
    try update(&self.cells[row]) { rowCells in
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
            highlightID: highlightID
          )
          rowCells[startColumn + updatedCellsCount] = cell

          updatedCellsCount += 1
        }
      }
    }
  }
}
