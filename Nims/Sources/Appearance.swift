//
//  Appearance.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Cocoa
import IdentifiedCollections
import RPC
import Tagged

actor Appearance {
  func cellSize() async -> CGSize {
    await self.font.cellSize
  }

  func stringAttributes(id: Highlight.ID? = nil) async -> [NSAttributedString.Key: Any] {
    await self.highlights.stringAttributes(id: id, font: self.font)
  }

  func setDefaultColors(foregroundRGB: Int, backgroundRGB: Int, specialRGB: Int) async {
    await self.highlights.setDefaultColors(
      foregroundRGB: foregroundRGB,
      backgroundRGB: backgroundRGB,
      specialRGB: specialRGB
    )
  }

  func apply(nvimAttr: [(String, Value)], forID id: Highlight.ID) async {
    await self.highlights.apply(nvimAttr: nvimAttr, forID: id)
  }

  private var font = Font()
  private var highlights = Highlights()
}

actor Font {
  var regularNSFont = NSFont.monospacedSystemFont(
    ofSize: 13,
    weight: .regular
  )

  var boldNSFont: NSFont {
    self.cachedBoldNSFont ?? {
      let new = NSFontManager.shared.convert(self.regularNSFont, toHaveTrait: .boldFontMask)
      self.cachedBoldNSFont = new
      return new
    }()
  }

  var italicNSFont: NSFont {
    self.cachedItalicNSFont ?? {
      let new = NSFontManager.shared.convert(self.regularNSFont, toHaveTrait: .italicFontMask)
      self.cachedItalicNSFont = new
      return new
    }()
  }

  var boldItalicNSFont: NSFont {
    self.cachedBoldItalicNSFont ?? {
      let new = NSFontManager.shared.convert(self.boldNSFont, toHaveTrait: .italicFontMask)
      self.cachedBoldItalicNSFont = new
      return new
    }()
  }

  var cellSize: CGSize {
    self.cachedCellSize ?? {
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

  func nsFont(highlight: Highlight? = nil) async -> NSFont {
    guard let highlight else {
      return self.regularNSFont
    }

    let isBold = await highlight.isBold
    let isItalic = await highlight.isItalic

    if isBold, isItalic {
      return self.boldItalicNSFont

    } else if isBold {
      return self.boldNSFont

    } else if isItalic {
      return self.italicNSFont

    } else {
      return self.regularNSFont
    }
  }

  private var cachedBoldNSFont: NSFont?
  private var cachedItalicNSFont: NSFont?
  private var cachedBoldItalicNSFont: NSFont?
  private var cachedCellSize: CGSize?
}

actor Highlights {
  func setDefaultColors(foregroundRGB: Int, backgroundRGB: Int, specialRGB: Int) async {
    await self.defaultForegroundColor.set(rgb: foregroundRGB)
    await self.defaultBackgroundColor.set(rgb: backgroundRGB)
    await self.defaultSpecialColor.set(rgb: specialRGB)
  }

  func apply(nvimAttr: [(String, Value)], forID id: Highlight.ID) async {
    let highlight = self.highlights[id: id] ?? {
      let new = Highlight(id: id)
      self.highlights.append(new)

      return new
    }()

    await highlight.apply(nvimAttr: nvimAttr)
  }

  func stringAttributes(id: Highlight.ID? = nil, font: Font) async -> [NSAttributedString.Key: Any] {
    let highlight = id.flatMap { self.highlights[id: $0] }

    return [
      .font: await font.nsFont(highlight: highlight),
      .foregroundColor: await self.foregroundColor(highlight: highlight),
      .backgroundColor: await self.backgroundColor(highlight: highlight),
      .underlineColor: await self.specialColor(highlight: highlight),
    ]
  }

  func foregroundColor(highlightID: Int? = nil) async -> Color {
    let highlight = highlightID.flatMap { self.highlights[$0] }
    return await self.foregroundColor(highlight: highlight)
  }

  func backgroundColor(highlightID: Int? = nil) async -> Color {
    let highlight = highlightID.flatMap { self.highlights[$0] }
    return await self.backgroundColor(highlight: highlight)
  }

  func specialColor(highlightID: Int? = nil) async -> Color {
    let highlight = highlightID.flatMap { self.highlights[$0] }
    return await self.specialColor(highlight: highlight)
  }

  private var defaultForegroundColor = Color(rgb: 0x00FF00)
  private var defaultBackgroundColor = Color(rgb: 0x000000)
  private var defaultSpecialColor = Color(rgb: 0xFF00FF)
  private var highlights = IdentifiedArrayOf<Highlight>()

  private func foregroundColor(highlight: Highlight? = nil) async -> Color {
    await highlight?.foregroundColor ?? self.defaultForegroundColor
  }

  private func backgroundColor(highlight: Highlight? = nil) async -> Color {
    await highlight?.backgroundColor ?? self.defaultBackgroundColor
  }

  private func specialColor(highlight: Highlight? = nil) async -> Color {
    await highlight?.specialColor ?? self.defaultSpecialColor
  }
}

actor Highlight: Identifiable {
  init(id: ID) {
    self.id = id
  }

  typealias ID = Tagged<Highlight, Int>

  let id: ID

  var isBold = false
  var isItalic = false

  var foregroundColor: Color?
  var backgroundColor: Color?
  var specialColor: Color?

  func apply(nvimAttr: [(String, Value)]) {
    for (key, value) in nvimAttr {
      switch key {
      case "foreground":
        if let value = value as? Int {
          self.foregroundColor = .init(rgb: value)
        }

      case "background":
        if let value = value as? Int {
          self.backgroundColor = .init(rgb: value)
        }

      case "special":
        if let value = value as? Int {
          self.specialColor = .init(rgb: value)
        }

      case "bold":
        if let value = value as? Bool {
          self.isBold = value
        }

      case "italic":
        if let value = value as? Bool {
          self.isItalic = value
        }

      default:
        break
      }
    }
  }
}

actor Color {
  init(rgb: Int) {
    self.rgb = rgb
  }

  var rgb: Int

  var nsColor: NSColor {
    self.cachedNSColor ?? {
      let new = NSColor(rgb: self.rgb)
      self.cachedNSColor = new

      return new
    }()
  }

  func set(rgb: Int) {
    self.rgb = rgb

    self.cachedNSColor = nil
  }

  private var cachedNSColor: NSColor?
}
