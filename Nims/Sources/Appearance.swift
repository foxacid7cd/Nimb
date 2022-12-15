// Copyright © 2022 foxacid7cd. All rights reserved.

import Cocoa
import IdentifiedCollections
import MessagePack
import SwiftUI

@MainActor
class Appearance {
  var cellSize: CGSize {
    font.cellSize
  }

  var defaultBackgroundColor: Color {
    highlights.backgroundColor()
  }

  func attributeContainer(
    forHighlightWithID id: Int? = nil
  ) -> AttributeContainer {
    highlights.attributeContainer(
      forHighlightWithID: id,
      font: font
    )
  }

  func setDefaultColors(foregroundRGB: Int, backgroundRGB: Int, specialRGB: Int) {
    highlights.setDefaultColors(
      foregroundRGB: foregroundRGB,
      backgroundRGB: backgroundRGB,
      specialRGB: specialRGB
    )
  }

  func apply(nvimAttr: [Value: Value], forHighlightWithID id: Int) {
    highlights.apply(nvimAttr: nvimAttr, forHighlightWithID: id)
  }

  func highlight(withID id: Int) async -> Highlight? {
    highlights.highlight(withID: id)
  }

  private var font = Font()
  private var highlights = Highlights()
}

@MainActor
class Font {
  var regularNSFont = NSFont(name: "BlexMono Nerd Font", size: 13)!

  var boldNSFont: NSFont {
    cachedBoldNSFont ?? {
      let new = NSFontManager.shared.convert(self.regularNSFont, toHaveTrait: .boldFontMask)
      self.cachedBoldNSFont = new
      return new
    }()
  }

  var italicNSFont: NSFont {
    cachedItalicNSFont ?? {
      let new = NSFontManager.shared.convert(self.regularNSFont, toHaveTrait: .italicFontMask)
      self.cachedItalicNSFont = new
      return new
    }()
  }

  var boldItalicNSFont: NSFont {
    cachedBoldItalicNSFont ?? {
      let new = NSFontManager.shared.convert(self.boldNSFont, toHaveTrait: .italicFontMask)
      self.cachedBoldItalicNSFont = new
      return new
    }()
  }

  var cellSize: CGSize {
    cachedCellSize ?? {
      let string = "A"
      var character = string.utf16.first!

      var glyph = CGGlyph()
      var advance = CGSize()
      CTFontGetGlyphsForCharacters(self.regularNSFont, &character, &glyph, 1)
      CTFontGetAdvancesForGlyphs(self.regularNSFont, .horizontal, &glyph, &advance, 1)
      let width = advance.width

      let ascent = CTFontGetAscent(self.regularNSFont)
      let descent = CTFontGetDescent(self.regularNSFont)
      let leading = CTFontGetLeading(self.regularNSFont)
      let height = ascent + descent + leading

      let cellSize = CGSize(width: width, height: height)
      self.cachedCellSize = cellSize

      return cellSize
    }()
  }

  func nsFont(highlight: Highlight? = nil) -> NSFont {
    guard
      let highlight
    else {
      return regularNSFont
    }

    let isBold = highlight.isBold
    let isItalic = highlight.isItalic

    if isBold, isItalic {
      return boldItalicNSFont
    } else if isBold {
      return boldNSFont
    } else if isItalic {
      return italicNSFont
    } else {
      return regularNSFont
    }
  }

  private var cachedBoldNSFont: NSFont?
  private var cachedItalicNSFont: NSFont?
  private var cachedBoldItalicNSFont: NSFont?
  private var cachedCellSize: CGSize?
}

@MainActor
class Highlights {
  func setDefaultColors(foregroundRGB: Int, backgroundRGB: Int, specialRGB: Int) {
    defaultForegroundColor = .init(rgb: foregroundRGB)
    defaultBackgroundColor = .init(rgb: backgroundRGB)
    defaultSpecialColor = .init(rgb: specialRGB)
  }

  func apply(nvimAttr: [Value: Value], forHighlightWithID id: Int) {
    let highlight = highlights[id: id] ?? {
      let new = Highlight(id: id)
      self.highlights.append(new)

      return new
    }()

    highlight.apply(nvimAttr: nvimAttr)
  }

  func attributeContainer(
    forHighlightWithID id: Int? = nil,
    font: Font
  ) -> AttributeContainer {
    let highlight = id.flatMap { self.highlight(withID: $0) }

    var container = AttributeContainer()
    container.font = font.nsFont(highlight: highlight)
    container.foregroundColor = foregroundColor(highlight: highlight)
    container.backgroundColor = backgroundColor(highlight: highlight)

//    let paragraphStyle = NSMutableParagraphStyle()
//    paragraphStyle.lineSpacing = 0
//    container.paragraphStyle = paragraphStyle

    return container
  }

  func foregroundColor(highlightID: Int? = nil) -> Color {
    let highlight = highlightID.flatMap { self.highlight(withID: $0) }
    return foregroundColor(highlight: highlight)
  }

  func backgroundColor(highlightID: Int? = nil) -> Color {
    let highlight = highlightID.flatMap { self.highlight(withID: $0) }
    return backgroundColor(highlight: highlight)
  }

  func specialColor(highlightID: Int? = nil) -> Color {
    let highlight = highlightID.flatMap { self.highlight(withID: $0) }
    return specialColor(highlight: highlight)
  }

  func highlight(withID id: Int) -> Highlight? {
    if id == 0 {
      return nil
    }

    return highlights[id: id] ?? {
      let new = Highlight(id: id)
      self.highlights.append(new)

      return new
    }()
  }

  private var defaultForegroundColor = Color(rgb: 0x00FF00)
  private var defaultBackgroundColor = Color(rgb: 0x000000)
  private var defaultSpecialColor = Color(rgb: 0xFF00FF)
  private var highlights = IdentifiedArrayOf<Highlight>()

  private func foregroundColor(highlight: Highlight? = nil) -> Color {
    highlight?.foregroundColor ?? defaultForegroundColor
  }

  private func backgroundColor(highlight: Highlight? = nil) -> Color {
    highlight?.backgroundColor ?? defaultBackgroundColor
  }

  private func specialColor(highlight: Highlight? = nil) -> Color {
    highlight?.specialColor ?? defaultSpecialColor
  }
}

@MainActor
class Highlight: Identifiable {
  init(id: Int) {
    self.id = id
  }

  let id: Int

  var isBold = false
  var isItalic = false

  var foregroundColor: Color?
  var backgroundColor: Color?
  var specialColor: Color?

  func apply(nvimAttr: [Value: Value]) {
    for (key, value) in nvimAttr {
      guard case let .string(key) = key else {
        continue
      }

      switch key {
      case "foreground":
        if case let .integer(integer) = value {
          foregroundColor = .init(rgb: integer)
        }

      case "background":
        if case let .integer(integer) = value {
          backgroundColor = .init(rgb: integer)
        }

      case "special":
        if case let .integer(integer) = value {
          specialColor = .init(rgb: integer)
        }

      case "bold":
        if case let .boolean(boolean) = value {
          isBold = boolean
        }

      case "italic":
        if case let .boolean(boolean) = value {
          isItalic = boolean
        }

      default:
        break
      }
    }
  }
}

private extension Color {
  init(rgb: Int, opacity: Double = 1) {
    self.init(
      red: Double((rgb & 0xFF0000) >> 16) / 255.0,
      green: Double((rgb & 0xFF00) >> 8) / 255.0,
      blue: Double(rgb & 0xFF) / 255.0,
      opacity: opacity
    )
  }
}

// @StoreActor
// class Color {
//  init(rgb: Int) {
//    self.rgb = rgb
//  }
//
//  var rgb: Int
//
//  var nsColor: NSColor {
//    cachedNSColor ?? {
//      let new = NSColor(rgb: self.rgb)
//      self.cachedNSColor = new
//
//      return new
//    }()
//  }
//
//  func set(rgb: Int) {
//    self.rgb = rgb
//
//    cachedNSColor = nil
//  }
//
//  private var cachedNSColor: NSColor?
// }
