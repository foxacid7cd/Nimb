// SPDX-License-Identifier: MIT

import AppKit

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
