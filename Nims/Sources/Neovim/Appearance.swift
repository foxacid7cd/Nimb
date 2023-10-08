// SPDX-License-Identifier: MIT

import Library

@PublicInit
public struct Appearance: Sendable {
  public var highlights: IntKeyedDictionary<Highlight> = [:]
  public var defaultForegroundColor: NimsColor = .black
  public var defaultBackgroundColor: NimsColor = .black
  public var defaultSpecialColor: NimsColor = .black

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

  public func foregroundColor(for highlightID: Highlight.ID) -> NimsColor {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return defaultForegroundColor
    }

    return highlight.isReverse ?
      highlight.backgroundColor ?? defaultBackgroundColor :
      highlight.foregroundColor ?? defaultForegroundColor
  }

  public func backgroundColor(for highlightID: Highlight.ID) -> NimsColor {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return defaultBackgroundColor
    }

    let color = highlight.isReverse ?
      highlight.foregroundColor ?? defaultForegroundColor :
      highlight.backgroundColor ?? defaultBackgroundColor

    let alpha = max(0, min(1, 1 - Double(highlight.blend) / 100))
    return color.with(alpha: alpha)
  }

  public func specialColor(for highlightID: Highlight.ID) -> NimsColor {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return defaultSpecialColor
    }

    return highlight.specialColor ?? (highlight.isReverse ? defaultBackgroundColor : defaultForegroundColor)
  }
}
