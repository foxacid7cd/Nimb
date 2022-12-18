//
//  Font.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 18.12.2022.
//

import AppKit
import Collections
import Tagged

public struct Font: Sendable, Hashable {
  var id: ID

  typealias ID = Tagged<Font, Int>

  init(
    id: ID
  ) {
    self.id = id
  }

  @MainActor
  public init(
    _ nsFont: NSFont
  ) {
    let id = BridgingService.shared.register(nsFont)

    self.init(id: id)
  }

  @MainActor
  public var nsFont: NSFont {
    BridgingService.shared.nsFont(for: id)
  }

  @MainActor
  public var cellSize: CGSize {
    BridgingService.shared.cellSize(for: id)
  }
}

@MainActor
final class BridgingService {
  static let shared = BridgingService()

  private var store = [(nsFont: NSFont, cellSize: CGSize)]()

  func register(_ nsFont: NSFont) -> Font.ID {
    let id = Font.ID(store.count)
    store.append(
      (nsFont: nsFont, cellSize: nsFont.cellSize)
    )

    return id
  }

  func nsFont(for id: Font.ID) -> NSFont {
    store[id.rawValue].nsFont
  }

  func cellSize(for id: Font.ID) -> CGSize {
    store[id.rawValue].cellSize
  }
}

extension NSFont {
  @MainActor
  fileprivate var cellSize: CGSize {
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

    return CGSize(width: width, height: height)
  }
}
