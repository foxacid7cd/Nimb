// SPDX-License-Identifier: MIT

import AppKit

@MainActor
final class FontBridge {
  static let shared = FontBridge()

  func wrap(_ appKit: NSFont) -> Font {
    let font = Font(
      id: .init(wrapped.count),
      cellWidth: appKit.makeCellWidth(),
      cellHeight: appKit.makeCellHeight()
    )

    let bold = NSFontManager.shared.convert(appKit, toHaveTrait: .boldFontMask)
    let italic = NSFontManager.shared.convert(appKit, toHaveTrait: .italicFontMask)
    let boldItalic = NSFontManager.shared.convert(bold, toHaveTrait: .italicFontMask)

    wrapped.append((appKit, bold, italic, boldItalic))
    return font
  }

  func unwrap(_ font: Font) -> (regular: NSFont, bold: NSFont, italic: NSFont, boldItalic: NSFont) {
    wrapped[font.id.rawValue]
  }

  private var wrapped = [(regular: NSFont, bold: NSFont, italic: NSFont, boldItalic: NSFont)]()
}

public extension Font {
  @MainActor
  init(_ appKit: NSFont) {
    self = FontBridge.shared.wrap(appKit)
  }

  @MainActor
  var appKit: (regular: NSFont, bold: NSFont, italic: NSFont, boldItalic: NSFont) {
    FontBridge.shared.unwrap(self)
  }
}

public extension NSFont {
  func makeCellWidth() -> Double {
    var character = "A".utf16.first!

    var glyph = CGGlyph()
    var advance = CGSize()
    CTFontGetGlyphsForCharacters(self, &character, &glyph, 1)
    CTFontGetAdvancesForGlyphs(self, .horizontal, &glyph, &advance, 1)

    return advance.width
  }

  func makeCellHeight() -> Double {
    let ascent = CTFontGetAscent(self)
    let descent = CTFontGetDescent(self)
    let leading = CTFontGetLeading(self)

    return ceil(ascent + descent + leading)
  }
}
