// SPDX-License-Identifier: MIT

import Tagged

public struct Highlight: Identifiable, Sendable {
  public init(
    id: Highlight.ID,
    foregroundColor: Color? = nil,
    backgroundColor: Color? = nil,
    specialColor: Color? = nil,
    isReverse: Bool,
    isItalic: Bool,
    isBold: Bool,
    decorations: Decorations,
    blend: Int
  ) {
    self.id = id
    self.foregroundColor = foregroundColor
    self.backgroundColor = backgroundColor
    self.specialColor = specialColor
    self.isReverse = isReverse
    self.isItalic = isItalic
    self.isBold = isBold
    self.decorations = decorations
    self.blend = blend
  }

  public typealias ID = Tagged<Self, Int>

  public var id: ID
  public var foregroundColor: Color?
  public var backgroundColor: Color?
  public var specialColor: Color?
  public var isReverse: Bool
  public var isItalic: Bool
  public var isBold: Bool
  public var decorations: Decorations
  public var blend: Int

  public struct Decorations: Hashable, Sendable {
    public init(
      isStrikethrough: Bool = false,
      isUnderline: Bool = false,
      isUndercurl: Bool = false,
      isUnderdouble: Bool = false,
      isUnderdotted: Bool = false,
      isUnderdashed: Bool = false
    ) {
      self.isStrikethrough = isStrikethrough
      self.isUnderline = isUnderline
      self.isUndercurl = isUndercurl
      self.isUnderdouble = isUnderdouble
      self.isUnderdotted = isUnderdotted
      self.isUnderdashed = isUnderdashed
    }

    public var isStrikethrough: Bool
    public var isUnderline: Bool
    public var isUndercurl: Bool
    public var isUnderdouble: Bool
    public var isUnderdotted: Bool
    public var isUnderdashed: Bool
  }
}

public extension Highlight.ID {
  static var `default`: Self {
    0
  }

  var isDefault: Bool {
    self == .default
  }
}
