//
//  NimsAppearance.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Cocoa
import Collections
import MessagePack

class NimsAppearance {
  @MainActor
  init(regularFont: NSFont) {
    self.regularFont = regularFont
    (self.boldFont, self.italicFont, self.boldItalicFont) = regularFont.makeFontVariants()
    self.cellSize = regularFont.makeCellSize()
  }

  @MainActor
  private(set) var boldFont: NSFont

  @MainActor
  private(set) var italicFont: NSFont

  @MainActor
  private(set) var boldItalicFont: NSFont

  @MainActor
  private(set) var cellSize: CGSize

  @MainActor
  private(set) var defaultForegroundColor = NSColor.clear

  @MainActor
  private(set) var defaultBackgroundColor = NSColor.clear

  @MainActor
  private(set) var defaultSpecialColor = NSColor.clear

  @MainActor
  private(set) var regularFont: NSFont

  @MainActor
  func stringAttributes(hlID: Int) -> [NSAttributedString.Key: Any] {
    guard hlID != 0, let highlight = self.highlights[hlID] else {
      return [
        .font: self.regularFont,
        .foregroundColor: self.defaultForegroundColor,
        .backgroundColor: self.defaultBackgroundColor,
        .underlineColor: self.defaultSpecialColor,
      ]
    }

    return [
      .font: self.font(highlight: highlight),
      .foregroundColor: self.foregroundColor(highlight: highlight),
      .backgroundColor: self.backgroundColor(highlight: highlight),
      .underlineColor: self.specialColor(highlight: highlight),
    ]
  }

  @MainActor
  func defaultColorsSet(rgbFg: Int, rgbBg: Int, rgbSp: Int) {
    self.defaultForegroundColor = NSColor(rgb: rgbFg)
    self.defaultBackgroundColor = NSColor(rgb: rgbBg)
    self.defaultSpecialColor = NSColor(rgb: rgbSp)
  }

  @MainActor
  func hlAttrDefine(id: Int, rgbAttr: [(key: String, value: MessageValue)]) {
    let highlight = self.highlights[id] ?? {
      let new = Highlight()
      self.highlights[id] = new
      return new
    }()

    for (key, value) in rgbAttr {
      switch key {
      case "foreground":
        if let foreground = value as? Int {
          highlight.foreground = foreground
          highlight.foregroundColor = nil
        }

      case "background":
        if let background = value as? Int {
          highlight.background = background
          highlight.backgroundColor = nil
        }

      case "special":
        if let special = value as? Int {
          highlight.special = special
          highlight.specialColor = nil
        }

      case "bold":
        if let value = value as? Bool {
          highlight.isBold = value
        }

      case "italic":
        if let value = value as? Bool {
          highlight.isItalic = value
        }

      default:
        break
      }
    }
  }

  @MainActor
  private var highlights = PersistentDictionary<Int, Highlight>()

  @MainActor
  private func font(highlight: Highlight) -> NSFont {
    if highlight.isBold {
      if highlight.isItalic {
        return self.boldItalicFont

      } else {
        return self.boldFont
      }
    } else {
      if highlight.isItalic {
        return self.italicFont

      } else {
        return self.regularFont
      }
    }
  }

  @MainActor
  private func foregroundColor(highlight: Highlight) -> NSColor {
    guard let foreground = highlight.foreground else {
      return self.defaultForegroundColor
    }

    return highlight.foregroundColor ?? {
      let color = NSColor(rgb: foreground)
      highlight.foregroundColor = color
      return color
    }()
  }

  @MainActor
  private func backgroundColor(highlight: Highlight) -> NSColor {
    guard let background = highlight.background else {
      return self.defaultBackgroundColor
    }

    return highlight.backgroundColor ?? {
      let color = NSColor(rgb: background)
      highlight.backgroundColor = color
      return color
    }()
  }

  @MainActor
  private func specialColor(highlight: Highlight) -> NSColor {
    guard let special = highlight.special else {
      return self.defaultSpecialColor
    }

    return highlight.specialColor ?? {
      let color = NSColor(rgb: special)
      highlight.specialColor = color
      return color
    }()
  }
}

private extension NSFont {
  func makeCellSize() -> CGSize {
    let string = "A"
    var character = string.utf16.first!

    var glyph = CGGlyph()
    var advance = CGSize()
    CTFontGetGlyphsForCharacters(self, &character, &glyph, 1)
    CTFontGetAdvancesForGlyphs(self, .horizontal, &glyph, &advance, 1)
    let width = advance.width

    let ascent = CTFontGetAscent(self)
    let descent = CTFontGetDescent(self)
    let leading = CTFontGetLeading(self)
    let height = ascent + descent + leading

    return .init(width: width, height: height)
  }

  func makeFontVariants() -> (bold: NSFont, italic: NSFont, boldItalic: NSFont) {
    let bold = NSFontManager.shared.convert(self, toHaveTrait: .boldFontMask)
    let italic = NSFontManager.shared.convert(self, toHaveTrait: .italicFontMask)
    let boldItalic = NSFontManager.shared.convert(bold, toHaveTrait: .italicFontMask)

    return (bold, italic, boldItalic)
  }
}

private class Highlight {
  var foreground: Int?
  var background: Int?
  var special: Int?

  var isBold = false
  var isItalic = false

  var foregroundColor: NSColor?
  var backgroundColor: NSColor?
  var specialColor: NSColor?
}
