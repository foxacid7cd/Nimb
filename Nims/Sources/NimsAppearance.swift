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
  var regularFont: NSFont {
    didSet {
      self.cellSize = self.regularFont.makeCellSize()
    }
  }

  @MainActor
  private(set) var cellSize: CGSize

  @MainActor
  private(set) var defaultForegroundColor = NSColor.clear

  @MainActor
  private(set) var defaultBackgroundColor = NSColor.clear

  @MainActor
  private(set) var defaultSpecialColor = NSColor.clear

  private var highlights = PersistentDictionary<Int, Highlight>()

  @MainActor
  init(regularFont: NSFont) {
    self.regularFont = regularFont
    self.cellSize = regularFont.makeCellSize()
  }

  @MainActor
  func stringAttributes(hlID: Int) -> [NSAttributedString.Key: Any] {
    [
      .font: self.regularFont,
      .foregroundColor: self.foregroundColor(hlID: hlID),
      .backgroundColor: self.backgroundColor(hlID: hlID),
      .underlineColor: self.specialColor(hlID: hlID)
    ]
  }

  @MainActor
  func foregroundColor(hlID: Int) -> NSColor {
    guard
      hlID != 0,
      let highlight = self.highlights[hlID],
      let foreground = highlight.foreground
    else {
      return self.defaultForegroundColor
    }

    return highlight.foregroundColor ?? {
      let color = NSColor(rgb: foreground)
      highlight.foregroundColor = color
      return color
    }()
  }

  @MainActor
  func backgroundColor(hlID: Int) -> NSColor {
    guard
      hlID != 0,
      let highlight = self.highlights[hlID],
      let background = highlight.background
    else {
      return self.defaultBackgroundColor
    }

    return highlight.backgroundColor ?? {
      let color = NSColor(rgb: background)
      highlight.backgroundColor = color
      return color
    }()
  }

  @MainActor
  func specialColor(hlID: Int) -> NSColor {
    guard
      hlID != 0,
      let highlight = self.highlights[hlID],
      let special = highlight.special
    else {
      return self.defaultSpecialColor
    }

    return highlight.specialColor ?? {
      let color = NSColor(rgb: special)
      highlight.specialColor = color
      return color
    }()
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
        highlight.foreground = value as? Int

      case "background":
        highlight.background = value as? Int

      case "special":
        highlight.special = value as? Int

      default:
        break
      }
    }
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
}

private class Highlight {
  var foreground: Int?
  var background: Int?
  var special: Int?

  var foregroundColor: NSColor?
  var backgroundColor: NSColor?
  var specialColor: NSColor?
}
