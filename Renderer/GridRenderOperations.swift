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

  public var row: Int
  public var columnsRange: Range<Int>
  public var text: String
  public var backgroundColor: Color
  public var foregroundColor: Color
  public var isBold: Bool
  public var isItalic: Bool
  public var isStrikethrough: Bool
  public var isUnderline: Bool
  public var isUndercurl: Bool
  public var isUnderdouble: Bool
  public var isUnderdotted: Bool
  public var isUnderdashed: Bool

  public init(
    row: Int,
    columnsRange: Range<Int>,
    text: String,
    backgroundColor: Color,
    foregroundColor: Color,
    isBold: Bool,
    isItalic: Bool,
    isStrikethrough: Bool,
    isUnderline: Bool,
    isUndercurl: Bool,
    isUnderdouble: Bool,
    isUnderdotted: Bool,
    isUnderdashed: Bool
  ) {
    self.row = row
    self.columnsRange = columnsRange
    self.text = text
    self.backgroundColor = backgroundColor
    self.foregroundColor = foregroundColor
    self.isBold = isBold
    self.isItalic = isItalic
    self.isStrikethrough = isStrikethrough
    self.isUnderline = isUnderline
    self.isUndercurl = isUndercurl
    self.isUnderdouble = isUnderdouble
    self.isUnderdotted = isUnderdotted
    self.isUnderdashed = isUnderdashed
  }

  public required init?(coder: NSCoder) {
    guard
      let row = coder.decodeObject(
        of: NSNumber.self,
        forKey: "row"
      ) as? Int,
      let columnsRangeLowerBound = coder.decodeObject(
        of: NSNumber.self,
        forKey: "columnsRangeLowerBound"
      ) as? Int,
      let columnsRangeUpperBound = coder.decodeObject(
        of: NSNumber.self,
        forKey: "columnsRangeUpperBound"
      ) as? Int,
      let text = coder.decodeObject(
        of: NSString.self,
        forKey: "text"
      ) as? String
    else {
      return nil
    }

    self.row = row
    columnsRange = columnsRangeLowerBound ..< columnsRangeUpperBound
    self.text = text
    backgroundColor = .init(
      rgb: coder.decodeInteger(forKey: "backgroundColorRGB"),
      alpha: coder.decodeDouble(forKey: "backgroundColorAlpha")
    )
    foregroundColor = .init(
      rgb: coder.decodeInteger(forKey: "foregroundColorRGB"),
      alpha: coder.decodeDouble(forKey: "foregroundColorAlpha")
    )
    isBold = coder.decodeBool(forKey: "isBold")
    isItalic = coder.decodeBool(forKey: "isItalic")
    isStrikethrough = coder.decodeBool(forKey: "isStrikethrough")
    isUnderline = coder.decodeBool(forKey: "isUnderline")
    isUndercurl = coder.decodeBool(forKey: "isUndercurl")
    isUnderdouble = coder.decodeBool(forKey: "isUnderdouble")
    isUnderdotted = coder.decodeBool(forKey: "isUnderdotted")
    isUnderdashed = coder.decodeBool(forKey: "isUnderdashed")
  }

  public func encode(with coder: NSCoder) {
    coder.encode(row, forKey: "row")
    coder.encode(columnsRange.lowerBound, forKey: "columnsRangeLowerBound")
    coder.encode(columnsRange.upperBound, forKey: "columnsRangeUpperBound")
    coder.encode(text, forKey: "text")
    coder.encode(backgroundColor.rgb, forKey: "backgroundColorRGB")
    coder.encode(backgroundColor.alpha, forKey: "backgroundColorAlpha")
    coder.encode(foregroundColor.rgb, forKey: "foregroundColorRGB")
    coder.encode(foregroundColor.alpha, forKey: "foregroundColorAlpha")
    coder.encode(isBold, forKey: "isBold")
    coder.encode(isItalic, forKey: "isItalic")
    coder.encode(isStrikethrough, forKey: "isStrikethrough")
    coder.encode(isUnderline, forKey: "isUnderline")
    coder.encode(isUndercurl, forKey: "isUndercurl")
    coder.encode(isUnderdouble, forKey: "isUnderdouble")
    coder.encode(isUnderdotted, forKey: "isUnderdotted")
    coder.encode(isUnderdashed, forKey: "isUnderdashed")
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
