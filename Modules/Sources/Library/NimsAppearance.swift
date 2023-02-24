// SPDX-License-Identifier: MIT

import AppKit
import IdentifiedCollections
import Tagged

public struct NimsAppearance {
  public init(
    font: NimsFont,
    highlights: IntKeyedDictionary<Highlight>,
    defaultForegroundColor: NimsColor,
    defaultBackgroundColor: NimsColor,
    defaultSpecialColor: NimsColor
  ) {
    self.font = font
    self.highlights = highlights
    self.defaultForegroundColor = defaultForegroundColor
    self.defaultBackgroundColor = defaultBackgroundColor
    self.defaultSpecialColor = defaultSpecialColor
  }

  public var font: NimsFont
  public var highlights: IntKeyedDictionary<Highlight>
  public var defaultForegroundColor: NimsColor
  public var defaultBackgroundColor: NimsColor
  public var defaultSpecialColor: NimsColor

  public var cellWidth: Double {
    font.cellWidth
  }

  public var cellHeight: Double {
    font.cellHeight
  }

  public var cellSize: CGSize {
    font.cellSize
  }

  public static let defaultValue = Self(
    font: .init(.monospacedSystemFont(ofSize: 12, weight: .regular)),
    highlights: [:],
    defaultForegroundColor: .init(rgb: 0xFFFFFF),
    defaultBackgroundColor: .init(rgb: 0x000000),
    defaultSpecialColor: .init(rgb: 0xFF0000)
  )

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

  public func isStrikethrough(for highlightID: Highlight.ID) -> Bool {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return false
    }

    return highlight.isStrikethrough
  }

  public func underlineStyle(for highlightID: Highlight.ID) -> NSUnderlineStyle {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return .init()
    }

    if highlight.isUnderline {
      return .single

    } else if highlight.isUndercurl {
      return .patternDashDot

    } else if highlight.isUnderdouble {
      return .double

    } else if highlight.isUnderdotted {
      return .patternDot

    } else if highlight.isUnderdashed {
      return .patternDash

    } else {
      return .init()
    }
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

    return highlight.isReverse ?
      highlight.foregroundColor ?? defaultForegroundColor :
      highlight.backgroundColor ?? defaultBackgroundColor
  }

  public func specialColor(for highlightID: Highlight.ID) -> NimsColor {
    guard highlightID != .zero, let highlight = highlights[highlightID] else {
      return defaultSpecialColor
    }

    return highlight.specialColor ?? (highlight.isReverse ? defaultBackgroundColor : defaultForegroundColor)
  }
}
