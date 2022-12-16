// Copyright © 2022 foxacid7cd. All rights reserved.

import Cocoa
import IdentifiedCollections
import MessagePack
import Overture
import SwiftUI

struct Appearance {
  var cellSize: CGSize {
    let nsFont = NSFont(name: "MesloLGS NF", size: 13)!
    let string = "A"
    var character = string.utf16.first!

    var glyph = CGGlyph()
    var advance = CGSize()
    CTFontGetGlyphsForCharacters(nsFont, &character, &glyph, 1)
    CTFontGetAdvancesForGlyphs(nsFont, .horizontal, &glyph, &advance, 1)
    let width = advance.width

    let ascent = CTFontGetAscent(nsFont)
    let descent = CTFontGetDescent(nsFont)
    let leading = CTFontGetLeading(nsFont)
    let height = ascent + descent + leading

    return CGSize(width: width, height: height)
  }

  mutating func defaultBackgroundColor() -> Color {
    highlights.backgroundColor()
  }

  mutating func attributeContainer(
    forHighlightWithID id: Int? = nil
  ) -> AttributeContainer {
    highlights.attributeContainer(
      forHighlightWithID: id,
      font: font
    )
  }

  mutating func setDefaultColors(foregroundRGB: Int, backgroundRGB: Int, specialRGB: Int) {
    highlights.setDefaultColors(
      foregroundRGB: foregroundRGB,
      backgroundRGB: backgroundRGB,
      specialRGB: specialRGB
    )
  }

  mutating func apply(nvimAttr: [Value: Value], forHighlightWithID id: Int) {
    highlights.apply(nvimAttr: nvimAttr, forHighlightWithID: id)
  }

  mutating func highlight(withID id: Int) async -> Highlight? {
    highlights.highlight(withID: id)
  }

  private var font = Font.custom("MesloLGS NF", size: 13)
  private var highlights = Highlights()
}

// @MainActor
// class Font {
//  var regularNSFont = NSFont(name: "MesloLGS NF", size: 13)!
//
//  var boldNSFont: NSFont {
//    cachedBoldNSFont ?? {
//      let new = NSFontManager.shared.convert(self.regularNSFont, toHaveTrait: .boldFontMask)
//      self.cachedBoldNSFont = new
//      return new
//    }()
//  }
//
//  var italicNSFont: NSFont {
//    cachedItalicNSFont ?? {
//      let new = NSFontManager.shared.convert(self.regularNSFont, toHaveTrait: .italicFontMask)
//      self.cachedItalicNSFont = new
//      return new
//    }()
//  }
//
//  var boldItalicNSFont: NSFont {
//    cachedBoldItalicNSFont ?? {
//      let new = NSFontManager.shared.convert(self.boldNSFont, toHaveTrait: .italicFontMask)
//      self.cachedBoldItalicNSFont = new
//      return new
//    }()
//  }
//
//  var cellSize: CGSize {
//    cachedCellSize ?? {
//      let string = "A"
//      var character = string.utf16.first!
//
//      var glyph = CGGlyph()
//      var advance = CGSize()
//      CTFontGetGlyphsForCharacters(self.regularNSFont, &character, &glyph, 1)
//      CTFontGetAdvancesForGlyphs(self.regularNSFont, .horizontal, &glyph, &advance, 1)
//      let width = advance.width
//
//      let ascent = CTFontGetAscent(self.regularNSFont)
//      let descent = CTFontGetDescent(self.regularNSFont)
//      let leading = CTFontGetLeading(self.regularNSFont)
//      let height = ascent + descent + leading
//
//      let cellSize = CGSize(width: width, height: height)
//      self.cachedCellSize = cellSize
//
//      return cellSize
//    }()
//  }
//
//  func nsFont(highlight: Highlight? = nil) -> NSFont {
//    guard
//      let highlight
//    else {
//      return regularNSFont
//    }
//
//    let isBold = highlight.isBold
//    let isItalic = highlight.isItalic
//
//    if isBold, isItalic {
//      return boldItalicNSFont
//
//    } else if isBold {
//      return boldNSFont
//
//    } else if isItalic {
//      return italicNSFont
//
//    } else {
//      return regularNSFont
//    }
//  }
//
//  private var cachedBoldNSFont: NSFont?
//  private var cachedItalicNSFont: NSFont?
//  private var cachedBoldItalicNSFont: NSFont?
//  private var cachedCellSize: CGSize?
// }

struct Highlights {
  mutating func setDefaultColors(foregroundRGB: Int, backgroundRGB: Int, specialRGB: Int) {
    defaultForegroundColor = .init(rgb: foregroundRGB)
    defaultBackgroundColor = .init(rgb: backgroundRGB)
    defaultSpecialColor = .init(rgb: specialRGB)
  }

  mutating func apply(nvimAttr: [Value: Value], forHighlightWithID id: Int) {
    update(&highlights[id: id]) { highlight in
      if highlight == nil {
        highlight = .init(id: id)
      }

      highlight!.apply(nvimAttr: nvimAttr)
    }
  }

  mutating func attributeContainer(
    forHighlightWithID id: Int? = nil,
    font: Font
  ) -> AttributeContainer {
    let highlight = id.flatMap { self.highlight(withID: $0) }

    var container = AttributeContainer()
    container.font = font
    container.foregroundColor = foregroundColor(highlight: highlight)
    container.backgroundColor = backgroundColor(highlight: highlight)
    container.ligature = 2

    return container
  }

  mutating func foregroundColor(highlightID: Int? = nil) -> Color {
    let highlight = highlightID.flatMap { self.highlight(withID: $0) }
    return foregroundColor(highlight: highlight)
  }

  mutating func backgroundColor(highlightID: Int? = nil) -> Color {
    let highlight = highlightID.flatMap { self.highlight(withID: $0) }
    return backgroundColor(highlight: highlight)
  }

  mutating func specialColor(highlightID: Int? = nil) -> Color {
    let highlight = highlightID.flatMap { self.highlight(withID: $0) }
    return specialColor(highlight: highlight)
  }

  mutating func highlight(withID id: Int) -> Highlight? {
    if id == 0 {
      return nil
    }

    if let index = highlights.index(id: id) {
      return highlights[index]

    } else {
      let new = Highlight(id: id)
      highlights[id: id] = new

      return new
    }
  }

  private var defaultForegroundColor = Color.white
  private var defaultBackgroundColor = Color.black
  private var defaultSpecialColor = Color.gray
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

struct Highlight: Identifiable {
  init(id: Int) {
    self.id = id
  }

  let id: Int

  private(set) var isBold = false
  private(set) var isItalic = false

  private(set) var foregroundColor: Color?
  private(set) var backgroundColor: Color?
  private(set) var specialColor: Color?

  mutating func apply(nvimAttr: [Value: Value]) {
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
