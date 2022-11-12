//
//  NSFontExtensions.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit

extension NSFont {
  func calculateCellSize(for character: Character) -> CGSize {
    var glyphs = [CGGlyph(0)]
    var advances = CGSize.zero
    CTFontGetGlyphsForCharacters(self, [character.utf16.first!], &glyphs, 1)
    CTFontGetAdvancesForGlyphs(self, .horizontal, glyphs, &advances, 1)
    let width = advances.width

    let ascent = CTFontGetAscent(self)
    let descent = CTFontGetDescent(self)
    let leading = CTFontGetLeading(self)
    let height = ceil(ascent + descent + leading)

    return .init(width: width, height: height)
  }
}
