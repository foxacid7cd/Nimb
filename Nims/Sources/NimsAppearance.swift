//
//  NimsAppearance.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Cocoa

class NimsAppearance {
  @MainActor
  var regularFont: NSFont {
    didSet {
      self.cellSize = regularFont.makeCellSize()
    }
  }
  
  @MainActor
  private(set) var cellSize: CGSize
  
  @MainActor
  init(regularFont: NSFont) {
    self.regularFont = regularFont
    self.cellSize = regularFont.makeCellSize()
  }
}

private extension NSFont {
  func makeCellSize() -> CGSize {
    let string = "M"
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
