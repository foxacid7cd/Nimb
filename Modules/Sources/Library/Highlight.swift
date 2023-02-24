// SPDX-License-Identifier: MIT

import Tagged

public struct Highlight: Identifiable {
  public init(
    id: Highlight.ID,
    foregroundColor: NimsColor? = nil,
    backgroundColor: NimsColor? = nil,
    specialColor: NimsColor? = nil,
    isReverse: Bool,
    isItalic: Bool,
    isBold: Bool,
    isStrikethrough: Bool,
    isUnderline: Bool,
    isUndercurl: Bool,
    isUnderdouble: Bool,
    isUnderdotted: Bool,
    isUnderdashed: Bool,
    blend: Int
  ) {
    self.id = id
    self.foregroundColor = foregroundColor
    self.backgroundColor = backgroundColor
    self.specialColor = specialColor
    self.isReverse = isReverse
    self.isItalic = isItalic
    self.isBold = isBold
    self.isStrikethrough = isStrikethrough
    self.isUnderline = isUnderline
    self.isUndercurl = isUndercurl
    self.isUnderdouble = isUnderdouble
    self.isUnderdotted = isUnderdotted
    self.isUnderdashed = isUnderdashed
    self.blend = blend
  }

  public typealias ID = Tagged<Self, Int>

  public var id: ID
  public var foregroundColor: NimsColor?
  public var backgroundColor: NimsColor?
  public var specialColor: NimsColor?
  public var isReverse: Bool
  public var isItalic: Bool
  public var isBold: Bool
  public var isStrikethrough: Bool
  public var isUnderline: Bool
  public var isUndercurl: Bool
  public var isUnderdouble: Bool
  public var isUnderdotted: Bool
  public var isUnderdashed: Bool
  public var blend: Int
}
