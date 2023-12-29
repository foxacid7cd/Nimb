// SPDX-License-Identifier: MIT

import Collections
import Library

@PublicInit
public struct Appearance: Sendable {
  public enum ObservedHighlightName: String, CaseIterable, Sendable {
    case normal = "Normal"
    case normalNC = "NormalNC"
    case normalFloat = "NormalFloat"
    case errorMsg = "ErrorMsg"
  }

  public var highlights: IntKeyedDictionary<Highlight> = [:]
  public var observedHighlights: TreeDictionary<ObservedHighlightName, (id: Int, kind: String)> = [:]
  public var defaultForegroundColor: NimsColor = .black
  public var defaultBackgroundColor: NimsColor = .black
  public var defaultSpecialColor: NimsColor = .black

  public var floatingWindowBorderColor: NimsColor {
    foregroundColor(for: .normalFloat)
      .with(alpha: 0.3)
  }

  public func observedHighlight(_ name: ObservedHighlightName) -> Highlight? {
    guard let (id, _) = observedHighlights[name] else {
      return nil
    }
    return highlights[id]
  }

  public func foregroundColor(for name: ObservedHighlightName) -> NimsColor {
    guard 
      let (id, _) = observedHighlights[name],
      let highlight = highlights[id],
      let foregroundColor = highlight.foregroundColor
    else {
      return defaultForegroundColor
    }
    return foregroundColor
  }

  public func backgroundColor(for name: ObservedHighlightName) -> NimsColor {
    guard
      let (id, _) = observedHighlights[name],
      let highlight = highlights[id],
      let backgroundColor = highlight.backgroundColor
    else {
      return defaultBackgroundColor
    }
    return backgroundColor
  }

  public func specialColor(for name: ObservedHighlightName) -> NimsColor {
    guard
      let (id, _) = observedHighlights[name],
      let highlight = highlights[id],
      let specialColor = highlight.specialColor
    else {
      return defaultSpecialColor
    }
    return specialColor
  }

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
