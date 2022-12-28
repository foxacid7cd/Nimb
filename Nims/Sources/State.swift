//
//  State.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 17.12.2022.
//

import IdentifiedCollections
import Instance
import Library
import Neovim
import Tagged

struct State: Sendable, Equatable {
  var instances: IdentifiedArrayOf<Instance.State>

  init(instances: IdentifiedArrayOf<Instance.State> = []) {
    self.instances = instances
  }
}

// struct State: Sendable {
//  init(cellSize: CGSize, defaultBackgroundColor: HighlightColor) {
//    self.cellSize = cellSize
//    self.defaultBackgroundColor = defaultBackgroundColor
//  }
//
//  struct Grid: Sendable, Identifiable {
//    init(id: Int) {
//      self.id = id
//    }
//
//    enum Win: Sendable {
//      case pos(frame: Rectangle)
//      case floatingPos(
//        anchor: String,
//        anchorGridID: Int,
//        anchorPosition: CGPoint
//      )
//    }
//
//    let id: Int
//    var isHidden = true
//    private(set) var size = Size()
//    private(set) var rows = [Row]()
//    private(set) var win: Win?
//    private(set) var gridFrame = CGRect()
//    private(set) var anchorGridID: Int?
//
//    mutating func set(size: Size) {
//      let delta = size.height - self.size.height
//
//      if delta > 0 {
//        for _ in 0 ..< delta {
//          rows.append(.init())
//        }
//
//      } else if delta < 0 {
//        rows.removeSubrange(
//          (rows.count + delta) ..< rows.count
//        )
//      }
//
//      for index in rows.indices {
//        let row = rows[index]
//        Task {
//          await row.set(width: size.width)
//        }
//      }
//
//      self.size = size
//      updateFrame()
//    }
//
//    mutating func set(win: Win?) {
//      self.win = win
//      updateFrame()
//    }
//
//    mutating func updateLine(origin: Point, data: [Value]) {
//      let row = rows[origin.y]
//      Task {
//        await row.update(
//          startIndex: origin.x,
//          data: data
//        )
//      }
//    }
//
//    mutating func offset(frame: Rectangle, by delta: Point) {
//      let isFullWidth = frame.size.width == size.width
//
//      guard isFullWidth else {
//        fatalError()
//      }
//
//      Task {
//        var sourceAttributedStrings = [AttributedString]()
//        for row in rows {
//          sourceAttributedStrings.append(
////            await row.attributedString
//          )
//        }
//      }
//
////      let sourceAttributedStrings = rows
////        .map(\.attributedString)
////
////      for yOffset in 0 ..< frame.size.height {
////        let sourceY = frame.origin.y + yOffset
////        let destinationY = sourceY - delta.y
////
////        guard destinationY >= 0, destinationY < rows.count else {
////          continue
////        }
////
////        rows[destinationY].set(
////          attributedString: sourceAttributedStrings[sourceY]
////        )
////      }
//    }
//
//    mutating func clear() {
//      for index in rows.indices {
//        rows[index].clear()
//      }
//    }
//
//    private mutating func updateFrame() {
//      if let win {
//        switch win {
//        case let .pos(frame):
//          anchorGridID = nil
//          gridFrame = .init(
//            origin: .init(
//              x: Double(frame.origin.x),
//              y: Double(frame.origin.y)
//            ),
//            size: .init(
//              width: Double(frame.size.width),
//              height: Double(frame.size.height)
//            )
//          )
//
//        case let .floatingPos(anchor, anchorGridID, anchorPosition):
//          self.anchorGridID = anchorGridID
//
//          let offset: CGPoint
//          switch anchor {
//          case "NW":
//            offset = .init()
//
//          case "NE":
//            offset = .init(x: -size.width, y: 0)
//
//          case "SW":
//            offset = .init(x: 0, y: -size.height)
//
//          case "SE":
//            offset = .init(x: -size.width, y: -size.height)
//
//          default:
//            fatalError("Unknown anchor value (\(anchor))")
//          }
//
//          gridFrame = .init(
//            origin: .init(
//              x: anchorPosition.x - offset.x,
//              y: anchorPosition.y - offset.y
//            ),
//            size: .init(
//              width: Double(size.width),
//              height: Double(size.height)
//            )
//          )
//        }
//
//      } else {
//        anchorGridID = nil
//        gridFrame = .init(
//          origin: .init(),
//          size: .init(
//            width: Double(size.width),
//            height: Double(size.height)
//          )
//        )
//      }
//    }
//  }
//
//  final class Row: Sendable {
//    final actor Wrapper: Sendable {
//      @MainActor
//      var attributedString = AttributedString()
//    }
//
//    let wrapper = Wrapper()
//
//    func set(width: Int) {
//      let delta = width - attributedString.characters.count
//
//      if delta > 0 {
//        let placeholder = "".padding(toLength: delta, withPad: " ", startingAt: 0)
//        attributedString.append(AttributedString(placeholder))
//
//      } else if delta < 0 {
//        let startIndex = attributedString.index(
//          attributedString.endIndex,
//          offsetByCharacters: delta
//        )
//        let range = startIndex ..< attributedString.endIndex
//        attributedString.removeSubrange(range)
//      }
//    }
//
//    func update(startIndex: Int, data: [Value]) {
//      var updatedCellsCount = 0
//
//      var highlight: (id: Int, startIndex: Int)?
//      var accumulator = ""
//
//      func snapshotHighlightGroupIfValid() {
//        guard let highlight, !accumulator.isEmpty else {
//          return
//        }
//
//        let startIndex = attributedString.index(
//          attributedString.startIndex,
//          offsetByCharacters: highlight.startIndex
//        )
//        let endIndex = attributedString.index(
//          startIndex,
//          offsetByCharacters: accumulator.count
//        )
//        attributedString.replaceSubrange(
//          startIndex ..< endIndex,
//          with: AttributedString(accumulator)
//        )
//      }
//
//      for element in data {
//        guard
//          let array = (/Value.array).extract(from: element),
//          !array.isEmpty,
//          let text = (/Value.string).extract(from: array[0])
//        else {
//          fatalError()
//        }
//
//        var repeatCount = 1
//
//        if array.count > 1 {
//          guard
//            let newHighlightID = (/Value.integer).extract(from: array[1])
//          else {
//            fatalError()
//          }
//
//          if highlight?.id != newHighlightID {
//            snapshotHighlightGroupIfValid()
//
//            highlight = (
//              id: newHighlightID,
//              startIndex: startIndex + updatedCellsCount
//            )
//            accumulator.removeAll(keepingCapacity: true)
//          }
//
//          if array.count > 2 {
//            guard
//              let newRepeatCount = (/Value.integer).extract(from: array[2])
//            else {
//              fatalError()
//            }
//
//            repeatCount = newRepeatCount
//          }
//        }
//
//        for _ in 0 ..< repeatCount {
//          accumulator.append(text)
//          updatedCellsCount += text.count
//        }
//      }
//      snapshotHighlightGroupIfValid()
//
//      return updatedCellsCount
//    }
//
//    func clear() {
//      let placeholder = "".padding(
//        toLength: attributedString.characters.count,
//        withPad: " ",
//        startingAt: 0
//      )
//      attributedString.replaceSubrange(
//        attributedString.startIndex ..< attributedString.endIndex,
//        with: AttributedString(placeholder)
//      )
//    }
//
//    func set(attributedString: AttributedString) {
//      if attributedString.characters.count != self.attributedString.characters.count {
//        preconditionFailure()
//      }
//
//      self.attributedString = attributedString
//    }
//  }
//
//  var cellSize: CGSize
//  var defaultBackgroundColor: HighlightColor
//  var grids = IdentifiedArrayOf<Grid>()
//  var outerGridSize = Size()
//  var cursor: (gridID: Int, position: Point)?
//  var currentTransactionEffects = Set<StateEffect>()
//
//  mutating func renewArrayPosition(forGridWithID id: Int) {
//    let oldIndex = grids.index(id: id)!
//    let grid = grids[oldIndex]
//
//    var newIndex = oldIndex
//    if let win = grid.win {
//      switch win {
//      case .pos:
//        for (offset, element) in grids.enumerated() {
//          guard offset < grids.count - 1 else {
//            newIndex = offset + 1
//            break
//          }
//
//          if let win = element.win, (/State.Grid.Win.floatingPos).extract(from: win) != nil {
//            newIndex = offset + 1
//            break
//          }
//        }
//
//      case .floatingPos:
//        newIndex = grids.count
//      }
//
//    } else {
//      for (offset, element) in grids.enumerated() {
//        guard offset < grids.count - 1 else {
//          newIndex = offset + 1
//          break
//        }
//
//        if element.win != nil {
//          newIndex = offset + 1
//          break
//        }
//      }
//    }
//
//    if newIndex != oldIndex {
//      grids.move(fromOffsets: [oldIndex], toOffset: newIndex)
//    }
//  }
// }
//
// enum StateEffect {
//  case initial
//  case outerGridSizeChanged
//  case gridsChanged
//  case defaultBackgroundColorChanged
//  case cursorChanged
// }
