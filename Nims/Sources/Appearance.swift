// Copyright © 2022 foxacid7cd. All rights reserved.

import Cocoa
import IdentifiedCollections
import MessagePack

actor Appearance {
  func cellSize() async -> CGSize {
    await font.cellSize
  }

  func stringAttributes(forHighlightWithID id: Int) async -> [NSAttributedString.Key: Any] {
    await highlights.stringAttributes(id: id, font: font)
  }

  func setDefaultColors(foregroundRGB: Int, backgroundRGB: Int, specialRGB: Int) async {
    await highlights.setDefaultColors(
      foregroundRGB: foregroundRGB,
      backgroundRGB: backgroundRGB,
      specialRGB: specialRGB
    )
  }

  func apply(nvimAttr: [Value: Value], forHighlightWithID id: Int) async {
    await highlights.apply(nvimAttr: nvimAttr, forHighlightWithID: id)
  }

  func highlight(withID id: Int) -> Highlight? {
    highlight(withID: id)
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

  func nsFont(highlight: Highlight? = nil) async -> NSFont {
    guard let highlight
    else {
      return regularNSFont
    }

    let isBold = await highlight.isBold
    let isItalic = await highlight.isItalic

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

actor Highlights {
  func setDefaultColors(foregroundRGB: Int, backgroundRGB: Int, specialRGB: Int) async {
    await defaultForegroundColor.set(rgb: foregroundRGB)
    await defaultBackgroundColor.set(rgb: backgroundRGB)
    await defaultSpecialColor.set(rgb: specialRGB)
  }

  func apply(nvimAttr: [Value: Value], forHighlightWithID id: Int) async {
    let highlight = highlights[id: id] ?? {
      let new = Highlight(id: id)
      self.highlights.append(new)

      return new
    }()

    await highlight.apply(nvimAttr: nvimAttr)
  }

  func stringAttributes(
    id: Highlight.ID? = nil,
    font: Font
  ) async -> [NSAttributedString.Key: Any] {
    let highlight = id.map { self.highlight(withID: $0) }

    return [
      .font: await font.nsFont(highlight: highlight),
      .foregroundColor: await foregroundColor(highlight: highlight),
      .backgroundColor: await backgroundColor(highlight: highlight),
      .underlineColor: await specialColor(highlight: highlight),
    ]
  }

  func foregroundColor(highlightID: Highlight.ID? = nil) async -> Color {
    let highlight = highlightID.map { self.highlight(withID: $0) }
    return await foregroundColor(highlight: highlight)
  }

  func backgroundColor(highlightID: Highlight.ID? = nil) async -> Color {
    let highlight = highlightID.map { self.highlight(withID: $0) }
    return await backgroundColor(highlight: highlight)
  }

  func specialColor(highlightID: Highlight.ID? = nil) async -> Color {
    let highlight = highlightID.map { self.highlight(withID: $0) }
    return await specialColor(highlight: highlight)
  }

  func highlight(withID id: Int) -> Highlight {
    highlights[id: id] ?? {
      let new = Highlight(id: id)
      self.highlights.append(new)

      return new
    }()
  }

  private var defaultForegroundColor = Color(rgb: 0x00FF00)
  private var defaultBackgroundColor = Color(rgb: 0x000000)
  private var defaultSpecialColor = Color(rgb: 0xFF00FF)
  private var highlights = IdentifiedArrayOf<Highlight>()

  private func foregroundColor(highlight: Highlight? = nil) async -> Color {
    await highlight?.foregroundColor ?? defaultForegroundColor
  }

  private func backgroundColor(highlight: Highlight? = nil) async -> Color {
    await highlight?.backgroundColor ?? defaultBackgroundColor
  }

  private func specialColor(highlight: Highlight? = nil) async -> Color {
    await highlight?.specialColor ?? defaultSpecialColor
  }
}

actor Highlight: Identifiable {
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

actor Color {
  init(rgb: Int) {
    self.rgb = rgb
  }

  var rgb: Int

  var nsColor: NSColor {
    cachedNSColor ?? {
      let new = NSColor(rgb: self.rgb)
      self.cachedNSColor = new

      return new
    }()
  }

  func set(rgb: Int) {
    self.rgb = rgb

    cachedNSColor = nil
  }

  private var cachedNSColor: NSColor?
}
