// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import CasePaths
import Cocoa
import Library
import MessagePack
import SwiftUI

@MainActor
class Grid: Identifiable {
  init(id: ID, size: Size, cellSize: CGSize) {
    self.id = id
    self.cellSize = cellSize

    width = size.width

    rows = (0 ..< size.height)
      .map { _ in
        let row = Row()
        row.set(width: size.width)
        return row
      }

    updateFrames()
  }

  struct Win {
    var frame: Rectangle
  }

  let id: Int

  private(set) var gridFrame = Rectangle()
  private(set) var frame = CGRect()

  private(set) var rows: [Row]

  func set(size: Size) {
    let delta = size.height - rows.count

    if delta > 0 {
      for _ in 0 ..< delta {
        rows.append(Row())
      }

    } else {
      rows = rows.dropLast(-delta)
    }

    for row in rows {
      row.set(width: size.width)
    }

    width = size.width
    updateFrames()
  }

  func set(win: Win?) {
    self.win = win
    updateFrames()
  }

  func set(cellSize: CGSize) {
    self.cellSize = cellSize
    updateFrames()
  }

  func update(origin: Point, data: [Value]) -> Int {
    rows[origin.y]
      .update(
        startIndex: origin.x,
        data: data
      )
  }

  func clear() {
    for row in rows {
      row.clear()
    }
  }

  func rowAttributedString(
    startingAt origin: Point,
    width: Int
  ) -> AttributedString {
    let row = rows[origin.y]
    let attributedString = row.attributedString

    let startIndex = attributedString
      .index(
        attributedString.startIndex,
        offsetByCharacters: origin.x
      )
    let endIndex = attributedString
      .index(
        startIndex,
        offsetByCharacters: width
      )
    let substring = attributedString[startIndex ..< endIndex]

    return AttributedString(substring)
  }

  private var width: Int
  private var win: Win?
  private var cellSize: CGSize

  private func updateFrames() {
    if let win {
      gridFrame = win.frame

    } else {
      gridFrame = .init(
        origin: .init(),
        size: .init(
          width: width,
          height: rows.count
        )
      )
    }

    frame = gridFrame * cellSize
  }
}

@MainActor
class Row {
  private(set) var attributedString = AttributedString()

  func set(width: Int) {
    let delta = width - attributedString.characters.count

    if delta > 0 {
      let placeholderString = "".padding(toLength: delta, withPad: " ", startingAt: 0)
      attributedString.append(AttributedString(placeholderString))

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
        with: AttributedString(accumulator)
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
      with: AttributedString(placeholderString)
    )
  }
}
