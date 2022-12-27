//
//  BridgingService.swift
//
//
//  Created by Yevhenii Matviienko on 28.12.2022.
//

import AppKit

@MainActor
final class BridgingService {
  static let shared = BridgingService()

  private var nsFonts = [NSFont]()

  func wrap(_ nsFont: NSFont) -> Font {
    let font = Font(
      id: .init(nsFonts.count),
      cellWidth: cellWidth(for: nsFont),
      cellHeight: cellHeight(for: nsFont)
    )

    nsFonts.append(nsFont)
    return font
  }

  func unwrap(_ font: Font) -> NSFont {
    nsFonts[font.id.rawValue]
  }

  private func cellWidth(for nsFont: NSFont) -> Double {
    var character = "A".utf16.first!

    var glyph = CGGlyph()
    var advance = CGSize()
    CTFontGetGlyphsForCharacters(nsFont, &character, &glyph, 1)
    CTFontGetAdvancesForGlyphs(nsFont, .horizontal, &glyph, &advance, 1)

    return advance.width
  }

  private func cellHeight(for nsFont: NSFont) -> Double {
    let ascent = CTFontGetAscent(nsFont)
    let descent = CTFontGetDescent(nsFont)
    let leading = CTFontGetLeading(nsFont)

    return ascent + descent + leading
  }
}

extension Font {
  @MainActor
  public init(
    _ nsFont: NSFont
  ) {
    self = BridgingService.shared.wrap(nsFont)
  }

  @MainActor
  public var nsFont: NSFont {
    BridgingService.shared.unwrap(self)
  }
}
