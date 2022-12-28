// SPDX-License-Identifier: MIT

import AppKit

@MainActor
final class FontBridge {
  static let shared = FontBridge()

  func wrap(_ appKit: NSFont) -> State.Font {
    let font = State.Font(
      id: .init(wrapped.count),
      cellWidth: cellWidth(for: appKit),
      cellHeight: cellHeight(for: appKit)
    )

    wrapped.append(appKit)
    return font
  }

  func unwrap(_ font: State.Font) -> NSFont {
    wrapped[font.id.rawValue]
  }

  private var wrapped = [NSFont]()

  private func cellWidth(for appKit: NSFont) -> Double {
    var character = "A".utf16.first!

    var glyph = CGGlyph()
    var advance = CGSize()
    CTFontGetGlyphsForCharacters(appKit, &character, &glyph, 1)
    CTFontGetAdvancesForGlyphs(appKit, .horizontal, &glyph, &advance, 1)

    return advance.width
  }

  private func cellHeight(for appKit: NSFont) -> Double {
    let ascent = CTFontGetAscent(appKit)
    let descent = CTFontGetDescent(appKit)
    let leading = CTFontGetLeading(appKit)

    return ascent + descent + leading
  }
}

public extension State.Font {
  @MainActor
  init(_ appKit: NSFont) {
    self = FontBridge.shared.wrap(appKit)
  }

  @MainActor
  var appKit: NSFont {
    FontBridge.shared.unwrap(self)
  }
}
