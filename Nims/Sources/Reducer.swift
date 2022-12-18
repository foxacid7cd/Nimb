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
import MessagePack
import Neovim
import OSLog
import Overture
import Tagged

struct State: Equatable, Sendable {
  var font: Font
  var grids: IdentifiedArrayOf<Grid>

  var outerGrid: Grid? {
    grids[id: .outer]
  }
}

struct Grid: Sendable, Equatable, Identifiable {
  var id: ID
  var cells: TwoDimensionalArray<Cell>

  typealias ID = Tagged<Grid, Int>
}

extension Grid.ID {
  static var outer: Self {
    1
  }

  var isOuter: Bool {
    self == .outer
  }
}

struct Cell: Sendable, Equatable {
  var text: String
  var highlightID: Highlight.ID
}

struct Highlight: Sendable, Equatable, Identifiable {
  var id: ID

  typealias ID = Tagged<Highlight, Int>
}

extension Highlight.ID {
  static var `default`: Self {
    0
  }

  var isDefault: Bool {
    self == .default
  }
}

struct Color: Sendable, Equatable {
  var rgb: Int
  var opacity: Double

  init(
    rgb: Int,
    opacity: Double = 1
  ) {
    self.rgb = rgb
    self.opacity = opacity
  }
}

enum Action: Sendable {
  case setFont(Font)
  case setDefaultBackgroundColor(Color)
  case appendUIEventBatch(UIEventBatch)
}

struct Reducer: ReducerProtocol {
  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case let .setFont(font):
      state.font = font
      return .none

    case let .appendUIEventBatch(batch):
      do {
        switch batch {
        case let .gridResize(decode):
          for event in try decode() {
            let id = Grid.ID(event.grid)

            update(&state.grids[id: .init(event.grid)]) { grid in
              if grid == nil {
                grid = .init(
                  id: id,
                  cells: .init(
                    size: .init(columnsCount: event.width, rowsCount: event.height),
                    repeatingElement: .init(text: " ", highlightID: .default)
                  )
                )

              } else {
                fatalError()
              }
            }
          }
          return .none

        case let .gridLine(decode):
          for event in try decode() {
            let id = Grid.ID(event.grid)

            try update(&state.grids[id: id]!) { grid in
              try grid.applyGridLineUpdate(
                row: event.row,
                startColumn: event.colStart,
                values: event.data
              )
            }
          }
          return .none

        default:
          return .none
        }

      } catch {
        os_log("Reduce failed with error (\(error))")

        return .none
      }

    case .setDefaultBackgroundColor(_):
      return .none
    }
  }
}

extension Grid {
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
