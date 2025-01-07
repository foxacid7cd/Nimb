// SPDX-License-Identifier: MIT

import AppKit

@PublicInit
public struct FontState: Equatable, @unchecked Sendable {
  public var regular: NSFont
  public var bold: NSFont
  public var italic: NSFont
  public var boldItalic: NSFont
  public var cellSize: CGSize

  public init(_ font: NSFont) {
    var regular = font
    let fontManager = NSFontManager.shared
    if fontManager.traits(of: regular).contains(.boldFontMask) {
      regular = fontManager.convert(regular, toNotHaveTrait: .boldFontMask)
    }
    if fontManager.traits(of: regular).contains(.italicFontMask) {
      regular = fontManager.convert(regular, toNotHaveTrait: .italicFontMask)
    }
    self.regular = regular

    bold = fontManager.convert(font, toHaveTrait: .boldFontMask)
    italic = fontManager.convert(font, toHaveTrait: .italicFontMask)
    boldItalic = fontManager.convert(bold, toHaveTrait: .italicFontMask)

    cellSize = .init(width: font.makeCellWidth(), height: font.makeCellHeight())
  }

  public func nsFontForDraw(for part: GridDrawRequestPart) -> NSFont {
    if part.isBold, part.isItalic {
      boldItalic
    } else if part.isBold {
      bold
    } else if part.isItalic {
      italic
    } else {
      regular
    }
  }
}
