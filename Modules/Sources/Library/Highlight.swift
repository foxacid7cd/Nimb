// SPDX-License-Identifier: MIT

import Tagged

public struct Highlight: Equatable, Identifiable {
  public init(
    id: ID,
    isBold: Bool = false,
    isItalic: Bool = false,
    foregroundColor: NimsColor? = nil,
    backgroundColor: NimsColor? = nil,
    specialColor: NimsColor? = nil
  ) {
    self.id = id
    self.isBold = isBold
    self.isItalic = isItalic
    self.foregroundColor = foregroundColor
    self.backgroundColor = backgroundColor
    self.specialColor = specialColor
  }

  public typealias ID = Tagged<Self, Int>

  public var id: ID
  public var isBold: Bool
  public var isItalic: Bool
  public var foregroundColor: NimsColor?
  public var backgroundColor: NimsColor?
  public var specialColor: NimsColor?
}
