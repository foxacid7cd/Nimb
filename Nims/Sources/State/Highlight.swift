// SPDX-License-Identifier: MIT

import Library

@PublicInit
public struct Highlight: Identifiable, Sendable {
  @PublicInit
  public struct Decorations: Hashable, Sendable {
    public var isStrikethrough: Bool = false
    public var isUnderline: Bool = false
    public var isUndercurl: Bool = false
    public var isUnderdouble: Bool = false
    public var isUnderdotted: Bool = false
    public var isUnderdashed: Bool = false
  }

  public static let DefaultID: Highlight.ID = 0

  public var id: Int
  public var foregroundColor: NimsColor? = nil
  public var backgroundColor: NimsColor? = nil
  public var specialColor: NimsColor? = nil
  public var isReverse: Bool = false
  public var isItalic: Bool = false
  public var isBold: Bool = false
  public var decorations: Decorations = .init()
  public var blend: Int = 0
}