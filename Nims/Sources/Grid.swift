// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import CasePaths
import Cocoa
import Library
import MessagePack

private let HighlightIDAttributeName = NSAttributedString.Key("HighlightIDAttributeName")

actor Grid: Identifiable {
  init(id: ID, size: Size) {
    self.id = id
    self.size = size

    (sendUpdate, updates) = AsyncChannel.pipe(bufferingPolicy: .unbounded)

    rows = (0 ..< size.height)
      .map { _ in
        Row(length: size.width)
      }
  }

  enum Update {
    case size
    case row(origin: Point, width: Int)
  }

  let id: Int
  let size: Size
  let updates: AsyncStream<Update>

  @MainActor
  func update(origin: Point, data: [Value]) async {
    let row = row(at: origin.y)
    let width = await row.update(startIndex: origin.x, data: data)
    await sendUpdate(.row(origin: origin, width: width))
  }

  @MainActor
  func rowAttributedString(
    startingAt origin: Point,
    length: Int,
    store: Store
  ) async -> NSAttributedString {
    let rowAttributedString = row(at: origin.y)
      .mutableAttributedString
      .attributedSubstring(
        from: .init(
          location: origin.x,
          length: length
        )
      )
      .mutableCopy() as! NSMutableAttributedString

    await withTaskGroup(of: Void.self) { group in
      rowAttributedString
        .enumerateAttribute(
          HighlightIDAttributeName,
          in: .init(location: 0, length: length)
        ) { highlightID, range, _ in
          guard let highlightiD = highlightID as? Int else {
            return
          }

          group.addTask { @MainActor in
            let attributes = await store.stringAttributes(forHighlightWithID: highlightiD)
            rowAttributedString.addAttributes(attributes, range: range)
          }
        }

      await group.waitForAll()
    }

    return rowAttributedString
  }

  @MainActor
  private var rows: [Row]
  private let sendUpdate: @Sendable (Update) async -> Void

  @MainActor
  private func row(at index: Int) -> Row {
    rows[index]
  }
}

actor Row {
  init(length: Int) {
    let attributedString = NSAttributedString(
      string: "".padding(toLength: length, withPad: " ", startingAt: 0)
    )
    mutableAttributedString = attributedString.mutableCopy() as! NSMutableAttributedString
  }

  @MainActor
  let mutableAttributedString: NSMutableAttributedString

  @MainActor
  func update(startIndex: Int, data: [Value]) async -> Int {
    mutableAttributedString.beginEditing()
    defer {
      self.mutableAttributedString.endEditing()
    }

    var updatedCellsCount = 0

    var highlight: (id: Int, startIndex: Int)?
    let accumulator = NSMutableString(capacity: mutableAttributedString.length)

    func snapshotHighlightGroupIfValid() {
      guard let highlight, accumulator.length > 0 else {
        return
      }

      let range = NSRange(location: highlight.startIndex, length: accumulator.length)
      mutableAttributedString.replaceCharacters(in: range, with: accumulator as String)
      mutableAttributedString.addAttribute(HighlightIDAttributeName, value: highlight.id, range: range)
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
          accumulator.deleteCharacters(
            in: .init(
              location: 0,
              length: accumulator.length
            )
          )
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
}
