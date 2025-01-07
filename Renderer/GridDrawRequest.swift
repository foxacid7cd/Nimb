// SPDX-License-Identifier: MIT

import AppKit

@objc(NimbGridDrawRequest)
public class GridDrawRequest: NSObject, NSSecureCoding {
  public static var supportsSecureCoding: Bool {
    true
  }

  public var gridID: Int
  public var parts: [GridDrawRequestPart]

  public init(gridID: Int, parts: [GridDrawRequestPart]) {
    self.gridID = gridID
    self.parts = parts
  }

  public required init?(coder: NSCoder) {
    guard
      let gridID = coder.decodeObject(
        of: NSNumber.self,
        forKey: "gridID"
      ) as? Int,
      let parts = coder.decodeArrayOfObjects(ofClass: GridDrawRequestPart.self, forKey: "parts")
    else {
      return nil
    }

    self.gridID = gridID
    self.parts = parts
  }

  public func encode(with coder: NSCoder) {
    coder.encode(gridID, forKey: "gridID")
    coder.encode(parts, forKey: "parts")
  }
}

@objc(NimbGridDrawRequestPart)
public class GridDrawRequestPart: NSObject, NSSecureCoding {
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
