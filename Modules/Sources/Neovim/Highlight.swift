// SPDX-License-Identifier: MIT

import Library

@PublicInit
public struct Highlight: Identifiable, Sendable {
  public var id: Int
  public var foregroundColor: Color? = nil
  public var backgroundColor: Color? = nil
  public var specialColor: Color? = nil
  public var isReverse: Bool = false
  public var isItalic: Bool = false
  public var isBold: Bool = false
  public var decorations: Decorations = .init()
  public var blend: Int = 0

  @PublicInit
  public struct Decorations: Hashable, Sendable {
    public var isStrikethrough: Bool = false
    public var isUnderline: Bool = false
    public var isUndercurl: Bool = false
    public var isUnderdouble: Bool = false
    public var isUnderdotted: Bool = false
    public var isUnderdashed: Bool = false
  }
}
