// SPDX-License-Identifier: MIT

import Foundation

@objc(NimbGridRenderOperations)
public class GridRenderOperations: NSObject, NSCoding, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public let array: [GridRenderOperation]

  public required init?(coder: NSCoder) {
    guard
      let array = coder.decodeArrayOfObjects(ofClass: GridRenderOperation.self, forKey: "array")
    else {
      return nil
    }
    self.array = array
  }

  init(array: [GridRenderOperation]) {
    self.array = array
  }

  public func encode(with coder: NSCoder) {
    coder.encode(array, forKey: "array")
  }
}

@objc(NimbGridRenderOperation)
public class GridRenderOperation: NSObject, NSCoding, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public let type: GridRenderOperationType
  public let draw: [GridRenderDrawOperationPart]?
  public let scroll: GridRenderScrollOperation?

  public init(
    type: GridRenderOperationType,
    draw: [GridRenderDrawOperationPart]?,
    scroll: GridRenderScrollOperation?
  ) {
    self.type = type
    self.draw = draw
    self.scroll = scroll
  }

  public required init?(coder: NSCoder) {
    guard
      let type = GridRenderOperationType(rawValue: coder.decodeInteger(forKey: "type"))
    else {
      return nil
    }

    self.type = type
    switch type {
    case .draw:
      guard
        let draw = coder.decodeArrayOfObjects(ofClass: GridRenderDrawOperationPart.self, forKey: "draw")
      else {
        return nil
      }
      self.draw = draw
      scroll = nil

    case .scroll:
      draw = nil
      guard
        let scroll = coder.decodeObject(
          of: GridRenderScrollOperation.self,
          forKey: "scroll"
        )
      else {
        return nil
      }
      self.scroll = scroll
    }
  }

  public func encode(with coder: NSCoder) {
    coder.encode(type.rawValue, forKey: "type")
    switch type {
    case .draw:
      coder.encode(draw!, forKey: "draw")
    case .scroll:
      coder.encode(scroll!, forKey: "scroll")
    }
  }
}

public enum GridRenderOperationType: Int {
  case draw
  case scroll
}

@objc(NimbGridRenderDrawOperationPart)
public class GridRenderDrawOperationPart: NSObject, NSCoding, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public let row: Int
  public let cells: [Cell]

  public init(row: Int, cells: [Cell]) {
    self.row = row
    self.cells = cells
  }

  public required init?(coder: NSCoder) {
    row = coder.decodeInteger(forKey: "row")

    if
      let cellTexts = coder
        .decodeArrayOfObjects(
          ofClass: NSString.self,
          forKey: "cells.text"
        ) as? [String],
        let cellHighlightIDs = coder
          .decodeArrayOfObjects(ofClass: NSNumber.self, forKey: "cells.highlightID") as? [Int]
    {
      cells = zip(cellTexts, cellHighlightIDs).map { text, highlightID in
        .init(text: text, highlightID: highlightID)
      }
    } else {
      return nil
    }
  }

  public func encode(with coder: NSCoder) {
    coder.encode(row, forKey: "row")

    let cellTexts = cells.map(\.text)
    coder.encode(cellTexts, forKey: "cells.text")

    let cellHighlightIDs = cells.map(\.highlightID)
    coder.encode(cellHighlightIDs, forKey: "cells.highlightID")
  }
}

@objc(NimbGridRenderScrollOperation)
public class GridRenderScrollOperation: NSObject, NSCoding, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public let rectangle: IntegerRectangle
  public let offset: IntegerSize

  public init(rectangle: IntegerRectangle, offset: IntegerSize) {
    self.rectangle = rectangle
    self.offset = offset
  }

  public required init?(coder: NSCoder) {
    rectangle = .init(
      origin: .init(
        column: coder.decodeInteger(forKey: "rectangle.origin.column"),
        row: coder.decodeInteger(forKey: "rectangle.origin.row")
      ),
      size: .init(
        columnsCount: coder.decodeInteger(forKey: "rectangle.size.columns"),
        rowsCount: coder.decodeInteger(forKey: "rectangle.size.rows")
      )
    )
    offset = .init(
      columnsCount: coder.decodeInteger(forKey: "offset.columns"),
      rowsCount: coder.decodeInteger(forKey: "offset.rows")
    )
  }

  public func encode(with coder: NSCoder) {
    coder.encode(rectangle.origin.column, forKey: "rectangle.origin.column")
    coder.encode(rectangle.origin.row, forKey: "rectangle.origin.row")
    coder.encode(rectangle.size.columnsCount, forKey: "rectangle.size.columns")
    coder.encode(rectangle.size.rowsCount, forKey: "rectangle.size.rows")
    coder.encode(offset.columnsCount, forKey: "offset.columns")
    coder.encode(offset.rowsCount, forKey: "offset.rows")
  }
}
