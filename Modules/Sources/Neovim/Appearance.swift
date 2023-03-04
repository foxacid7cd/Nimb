// SPDX-License-Identifier: MIT

import Library
import Tagged

public struct Appearance: Sendable {
  public init(
    highlights: IntKeyedDictionary<Highlight> = [:],
    defaultForegroundColor: Color = .init(rgb: 0xFFFFFF),
    defaultBackgroundColor: Color = .init(rgb: 0x000000),
    defaultSpecialColor: Color = .init(rgb: 0xFF00FF)
  ) {
    self.highlights = highlights
    self.defaultForegroundColor = defaultForegroundColor
    self.defaultBackgroundColor = defaultBackgroundColor
    self.defaultSpecialColor = defaultSpecialColor
  }

  public var highlights: IntKeyedDictionary<Highlight>
  public var defaultForegroundColor: Color
  public var defaultBackgroundColor: Color
  public var defaultSpecialColor: Color

  public func isItalic(for highlightID: Highlight.ID) -> Bool {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return false
    }

    return highlight.isItalic
  }

  public func isBold(for highlightID: Highlight.ID) -> Bool {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return false
    }

    return highlight.isBold
  }

  public func decorations(for highlightID: Highlight.ID) -> Highlight.Decorations {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return .init()
    }

    return highlight.decorations
  }

  public func foregroundColor(for highlightID: Highlight.ID) -> Color {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return defaultForegroundColor
    }

    return highlight.isReverse ?
      highlight.backgroundColor ?? defaultBackgroundColor :
      highlight.foregroundColor ?? defaultForegroundColor
  }

  public func backgroundColor(for highlightID: Highlight.ID) -> Color {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return defaultBackgroundColor
    }

    return highlight.isReverse ?
      highlight.foregroundColor ?? defaultForegroundColor :
      highlight.backgroundColor ?? defaultBackgroundColor
  }

  public func specialColor(for highlightID: Highlight.ID) -> Color {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return defaultSpecialColor
    }

    return highlight.specialColor ?? (highlight.isReverse ? defaultBackgroundColor : defaultForegroundColor)
  }
}
