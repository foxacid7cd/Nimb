// SPDX-License-Identifier: MIT

import Collections

@PublicInit
public struct Appearance: Sendable {
  public enum ObservedHighlightName: String, CaseIterable, Sendable {
    case normal = "Normal"
    case normalNC = "NormalNC"
    case normalFloat = "NormalFloat"
    case errorMsg = "ErrorMsg"
    case special = "Special"
    case pmenu = "Pmenu"
    case pmenuSel = "PmenuSel"
    case pmenuKind = "PmenuKind"
    case pmenuKindSel = "PmenuKindSel"
    case pmenuExtra = "PmenuExtra"
    case pmenuExtraSel = "PmenuExtraSel"
    case tabLine = "TabLine"
    case tabLineFill = "TabLineFill"
    case tabLineSel = "TabLineSel"
  }

  public var highlights: IntKeyedDictionary<Highlight> = [:]
  public var observedHighlights: TreeDictionary<
    ObservedHighlightName,
    (id: Int?, kind: String?)
  > =
    [:]
  public var defaultForegroundColor: Color = .black
  public var defaultBackgroundColor: Color = .black
  public var defaultSpecialColor: Color = .black

  public func observedHighlight(_ name: ObservedHighlightName) -> Highlight? {
    guard let (id, _) = observedHighlights[name], let id else {
      return nil
    }
    return highlights[id]
  }

  public func isItalic(for name: ObservedHighlightName) -> Bool {
    guard
      let (id, _) = observedHighlights[name],
      let id,
      let highlight = highlights[id]
    else {
      return false
    }
    return highlight.isItalic
  }

  public func isBold(for name: ObservedHighlightName) -> Bool {
    guard
      let (id, _) = observedHighlights[name],
      let id,
      let highlight = highlights[id]
    else {
      return false
    }
    return highlight.isBold
  }

  public func foregroundColor(for name: ObservedHighlightName) -> Color {
    guard
      let (id, _) = observedHighlights[name],
      let id,
      let highlight = highlights[id],
      let foregroundColor = highlight.foregroundColor
    else {
      return defaultForegroundColor
    }
    return foregroundColor
  }

  public func backgroundColor(for name: ObservedHighlightName) -> Color {
    guard
      let (id, _) = observedHighlights[name],
      let id,
      let highlight = highlights[id]
    else {
      return defaultBackgroundColor
    }
    return (highlight.backgroundColor ?? defaultBackgroundColor)
      .with(alpha: highlight.backgroundColorAlpha)
  }

  public func specialColor(for name: ObservedHighlightName) -> Color {
    guard
      let (id, _) = observedHighlights[name],
      let id,
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

  public func isReverse(for highlightID: Highlight.ID) -> Bool {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return false
    }

    return highlight.isReverse
  }

  public func decorations(for highlightID: Highlight.ID) -> Highlight
    .Decorations
  {
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

    let color = highlight.isReverse ?
      highlight.foregroundColor ?? defaultForegroundColor :
      highlight.backgroundColor ?? defaultBackgroundColor

    return color.with(alpha: highlight.backgroundColorAlpha)
  }

  public func specialColor(for highlightID: Highlight.ID) -> Color {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return defaultSpecialColor
    }

    return highlight
      .specialColor ??
      (highlight.isReverse ? defaultBackgroundColor : defaultForegroundColor)
  }
}
