// SPDX-License-Identifier: MIT

import AppKit
import Tagged

public struct NimsFont: Sendable, Equatable {
  public init(
    id: ID,
    cellWidth: Double,
    cellHeight: Double
  ) {
    self.id = id
    self.cellWidth = cellWidth
    self.cellHeight = cellHeight
  }

  public typealias ID = Tagged<Self, Int>

  public var id: ID
  public var cellWidth: Double
  public var cellHeight: Double

  public var cellSize: CGSize {
    .init(width: cellWidth, height: cellHeight)
  }

  public init(_ appKit: NSFont) {
    self = FontBridge.shared.wrap(appKit)
  }

  public var appKit: (regular: NSFont, bold: NSFont, italic: NSFont, boldItalic: NSFont) {
    FontBridge.shared.unwrap(self)
  }
}

final class FontBridge {
  static let shared = FontBridge()

  func wrap(_ appKit: NSFont) -> NimsFont {
    let font = NimsFont(
      id: .init(wrapped.count),
      cellWidth: appKit.makeCellWidth(),
      cellHeight: appKit.makeCellHeight()
    )

    let bold = NSFontManager.shared.convert(appKit, toHaveTrait: .boldFontMask)
    let italic = NSFontManager.shared.convert(appKit, toHaveTrait: .italicFontMask)
    let boldItalic = NSFontManager.shared.convert(bold, toHaveTrait: .italicFontMask)

    dispatchQueue.sync(flags: [.barrier]) {
      wrapped.append((appKit, bold, italic, boldItalic))
    }
    return font
  }

  func unwrap(_ font: NimsFont) -> (regular: NSFont, bold: NSFont, italic: NSFont, boldItalic: NSFont) {
    dispatchQueue.sync {
      wrapped[font.id.rawValue]
    }
  }

  private lazy var dispatchQueue = DispatchQueue(
    label: "foxacid7cd.FontBridge.\(ObjectIdentifier(self))",
    attributes: .concurrent
  )
  private var wrapped = [(regular: NSFont, bold: NSFont, italic: NSFont, boldItalic: NSFont)]()
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
