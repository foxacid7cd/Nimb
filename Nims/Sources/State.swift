// Copyright © 2022 foxacid7cd. All rights reserved.

import CasePaths
import IdentifiedCollections
import MessagePack
import SwiftUI

struct State {
  init(cellSize: CGSize, defaultBackgroundColor: Color) {
    self.cellSize = cellSize
    self.defaultBackgroundColor = defaultBackgroundColor
  }

  struct Grid: Identifiable {
    enum Win {
      case pos(frame: Rectangle)
    }

    let id: Int
    var size = Size()
    var rows = [Row]()
    var win: Win?
    private(set) var frame = Rectangle()

    mutating func updateFrame() {
      if let win {
        switch win {
        case let .pos(frame):
          self.frame = frame
        }

      } else {
        frame = .init(
          origin: .init(),
          size: size
        )
      }
    }
  }

  @MainActor
  class Row {
    nonisolated init(appearance: Appearance) {
      self.appearance = appearance
    }

    private(set) var attributedString = AttributedString()

    func set(width: Int) {
      let delta = width - attributedString.characters.count

      if delta > 0 {
        let placeholderString = "".padding(toLength: delta, withPad: " ", startingAt: 0)
        attributedString.append(
          AttributedString(
            placeholderString,
            attributes: appearance.attributeContainer()
          )
        )

      } else {
        let startIndex = attributedString.index(
          attributedString.endIndex,
          offsetByCharacters: delta
        )
        let range = startIndex ..< attributedString.endIndex
        attributedString.removeSubrange(range)
      }
    }

    func update(startIndex: Int, data: [Value]) -> Int {
      var updatedCellsCount = 0

      var highlight: (id: Int, startIndex: Int)?
      var accumulator = ""

      func snapshotHighlightGroupIfValid() {
        guard let highlight, !accumulator.isEmpty else {
          return
        }

        let startIndex = attributedString.index(
          attributedString.startIndex,
          offsetByCharacters: highlight.startIndex
        )
        let endIndex = attributedString.index(
          startIndex,
          offsetByCharacters: accumulator.count
        )
        attributedString.replaceSubrange(
          startIndex ..< endIndex,
          with: AttributedString(
            accumulator,
            attributes: appearance.attributeContainer(
              forHighlightWithID: highlight.id
            )
          )
        )
      }

      for element in data {
        guard var casted = element[/Value.array]
        else {
          fatalError("Not an array")
        }

        guard let text = casted.removeFirst()[/Value.string] else {
          fatalError("Not a text")
        }

        var repeatCount = 1

        if !casted.isEmpty {
          guard
            let newHighlightID = casted.removeFirst()[/Value.integer]
          else {
            fatalError("Not an highlight id")
          }

          if highlight?.id != newHighlightID {
            snapshotHighlightGroupIfValid()

            highlight = (
              id: newHighlightID,
              startIndex: startIndex + updatedCellsCount
            )
            accumulator.removeAll(keepingCapacity: true)
          }

          if !casted.isEmpty {
            guard let newRepeatCount = casted.removeFirst()[/Value.integer]
            else {
              fatalError("Not a repeat count")
            }
            repeatCount = newRepeatCount
          }
        }

        for _ in 0 ..< repeatCount {
          accumulator.append(text)
          updatedCellsCount += 1
        }
      }
      snapshotHighlightGroupIfValid()

      return updatedCellsCount
    }

    func clear() {
      let placeholderString = "".padding(
        toLength: attributedString.characters.count,
        withPad: " ",
        startingAt: 0
      )
      attributedString.replaceSubrange(
        attributedString.startIndex ..< attributedString.endIndex,
        with: AttributedString(
          placeholderString,
          attributes: appearance.attributeContainer()
        )
      )
    }

    private let appearance: Appearance
  }

  var cellSize: CGSize
  var defaultBackgroundColor: Color
  var grids = IdentifiedArrayOf<Grid>()
  var cachedOuterGridSize = Size()
  var gridsChangedInTransaction = false
}

enum StateEffect {
  case initial
  case outerGridSizeChanged
  case gridsChanged
  case defaultBackgroundColorChanged
}
