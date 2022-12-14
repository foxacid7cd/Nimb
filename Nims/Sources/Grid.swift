// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import CasePaths
import Cocoa
import Library
import MessagePack

actor Grid: Identifiable {
  init(appearance: Appearance, id: ID, size: Size) {
    self.appearance = appearance
    self.id = id
    self.size = size

    (sendUpdate, updates) = AsyncChannel.pipe(bufferingPolicy: .unbounded)

    rows = (0 ..< size.height)
      .map { _ in
        Row(appearance: appearance, length: size.width)
      }
  }

  typealias ID = Int

  enum Update {
    case size
    case row(origin: Point, width: Int)
  }

  let id: ID
  let size: Size
  let updates: AsyncStream<Update>

  func update(origin: Point, data: [Value]) async {
    let row = row(at: origin.y)
    let width = await row.update(startIndex: origin.x, data: data)
    await sendUpdate(.row(origin: origin, width: width))
  }

  private let appearance: Appearance
  private var rows: [Row]
  private let sendUpdate: @Sendable (Update)
    async -> Void

  private func row(at index: Int) -> Row {
    rows[index]
  }
}

actor Row {
  init(appearance: Appearance, length: Int) {
    self.appearance = appearance

    let cells = (0 ..< length)
      .map { Cell(text: " ", indexInRow: $0) }
    self.cells = cells

    let highlightGroups = [
      HighlightGroup(
        highlight: nil,
        cells: cells
      ),
    ]
    self.highlightGroups = highlightGroups

    highlightGroups
      .enumerated()
      .forEach { $0.element.index = $0.offset }
  }

  func update(startIndex: Int, data: [Value]) async -> Int {
    var updatedCellsCount = 0

    var highlightID: Highlight.ID?
    var highlightGroupCells = [Cell]()

    var createHighlightGroupParametersBatch = [CreateHighlightGroupParameters]()

    func snapshotCreateHighlightGroupParametersIfValid() {
      guard !highlightGroupCells.isEmpty
      else {
        return
      }

      createHighlightGroupParametersBatch.append((highlightID, highlightGroupCells))
    }

    for element in data {
      guard var casted = element[/Value.array]
      else {
        fatalError("Not an array")
      }

      guard let text = casted.removeFirst()[/Value.string]
      else {
        fatalError("Not a text")
      }

      var repeatCount = 1

      if !casted.isEmpty {
        guard let newRawHighlightID = casted.removeFirst()[/Value.integer]
        else {
          fatalError("Not an highlight id")
        }
        let newHighlightID = Highlight.ID(newRawHighlightID)

        if highlightID != newHighlightID {
          snapshotCreateHighlightGroupParametersIfValid()

          highlightID = newHighlightID
          highlightGroupCells.removeAll()
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
        let cellIndexInRow = startIndex + updatedCellsCount

        let cell = cells[cellIndexInRow]
        cell.text = text
        cell.indexInHighlightGroup = highlightGroupCells.count
        highlightGroupCells.append(cell)

        updatedCellsCount += 1
      }
    }
    snapshotCreateHighlightGroupParametersIfValid()

    await createHighlightGroups(
      parametersBatch: createHighlightGroupParametersBatch
    )

    return updatedCellsCount
  }

  private let appearance: Appearance
  private var cells: [Cell]
  private var highlightGroups: [HighlightGroup]

  private func createHighlightGroups(parametersBatch: [CreateHighlightGroupParameters]) async {
    let firstUpdatedCell = parametersBatch.first!.cells.first!
    let lastUpdatedCell = parametersBatch.last!.cells.last!

    let firstAffectedHighlightGroup = firstUpdatedCell.highlightGroup!
    let lastAffectedHighlightGroup = lastUpdatedCell.highlightGroup!

    let affectedHighlightGroupsRange = firstAffectedHighlightGroup
      .index! ..< lastAffectedHighlightGroup.index! + 1

    let firstAffectedCell = firstAffectedHighlightGroup.cells.first!
    let lastAffectedCell = lastAffectedHighlightGroup.cells.last!

    var newHighlightGroups = [HighlightGroup]()

    let newFirstAffectedHighlightGroupLength = firstUpdatedCell.indexInRow - firstAffectedCell
      .indexInRow
    if newFirstAffectedHighlightGroupLength > 0 {
      let removeLastCount = firstAffectedHighlightGroup.cells
        .count - newFirstAffectedHighlightGroupLength
      firstAffectedHighlightGroup.cells.removeLast(removeLastCount)
      firstAffectedHighlightGroup.cells.enumerated()
        .forEach { $0.element.indexInHighlightGroup = $0.offset }

      newHighlightGroups.append(firstAffectedHighlightGroup)
    }

    for parameters in parametersBatch {
      let newHighlightGroup = HighlightGroup(
        highlight: await { () -> Highlight? in
          guard
            let id = parameters.highlightID
          else {
            return nil
          }

          return await self.appearance.highlight(withID: id)
        }(),
        cells: parameters.cells
      )
      newHighlightGroups.append(newHighlightGroup)
    }

    let newLastAffectedHighlightGroupLength = lastAffectedCell.indexInRow - lastUpdatedCell
      .indexInRow
    if newLastAffectedHighlightGroupLength > 0 {
      let removeFirstCount = lastAffectedHighlightGroup.cells
        .count - newLastAffectedHighlightGroupLength
      lastAffectedHighlightGroup.cells.removeFirst(removeFirstCount)
      lastAffectedHighlightGroup.cells.enumerated()
        .forEach { $0.element.indexInHighlightGroup = $0.offset }

      newHighlightGroups.append(lastAffectedHighlightGroup)
    }

    highlightGroups.replaceSubrange(
      affectedHighlightGroupsRange,
      with: newHighlightGroups
    )

    highlightGroups.enumerated()
      .forEach { $0.element.index = $0.offset }
  }
}

private typealias CreateHighlightGroupParameters = (
  highlightID: Highlight.ID?,
  cells: [Cell]
)

private class HighlightGroup {
  init(highlight: Highlight?, cells: [Cell]) {
    self.highlight = highlight
    self.cells = cells

    cells.enumerated()
      .forEach { index, cell in
        cell.indexInHighlightGroup = index
        cell.highlightGroup = self
      }
  }

  let highlight: Highlight?
  var cells: [Cell]

  var index: Int?
}

private class Cell {
  init(
    text: String,
    indexInRow: Int
  ) {
    self.text = text
    self.indexInRow = indexInRow
  }

  var text: String
  var indexInRow: Int

  var indexInHighlightGroup: Int?
  var highlightGroup: HighlightGroup?
}
