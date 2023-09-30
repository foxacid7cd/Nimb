// SPDX-License-Identifier: MIT

import AppKit
import Library

@PublicInit
public struct NimsFont: Sendable, Hashable {
  @MainActor
  public init(_ appKit: NSFont) {
    self = FontBridge.shared.wrap(appKit)
  }

  public var id: Int = 0

  @MainActor
  public var cellWidth: Double {
    unwrapped.cellWidth
  }

  @MainActor
  public var cellHeight: Double {
    unwrapped.cellHeight
  }

  @MainActor
  public var cellSize: CGSize {
    .init(width: cellWidth, height: cellHeight)
  }

  @MainActor
  public func nsFont(isBold: Bool = false, isItalic: Bool = false) -> NSFont {
    if isBold, isItalic {
      unwrapped.boldItalic

    } else if isBold {
      unwrapped.bold

    } else if isItalic {
      unwrapped.italic

    } else {
      unwrapped.regular
    }
  }

  @MainActor
  private var unwrapped: FontBridge.WrappedFont {
    FontBridge.shared.unwrap(self)
  }
}

@MainActor
final class FontBridge {
  struct WrappedFont {
    var regular: NSFont
    var bold: NSFont
    var italic: NSFont
    var boldItalic: NSFont
    var cellWidth: Double
    var cellHeight: Double
  }

  static let shared = FontBridge()

  func wrap(_ appKit: NSFont) -> NimsFont {
    let bold = NSFontManager.shared.convert(appKit, toHaveTrait: .boldFontMask)
    let italic = NSFontManager.shared.convert(appKit, toHaveTrait: .italicFontMask)
    let boldItalic = NSFontManager.shared.convert(bold, toHaveTrait: .italicFontMask)

    let cellWidth = appKit.makeCellWidth()
    let cellHeight = appKit.makeCellHeight()

    let font = NimsFont(id: .init(wrappedFonts.count))
    wrappedFonts.append(.init(
      regular: appKit,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
      cellWidth: cellWidth,
      cellHeight: cellHeight
    ))
    return font
  }

  func unwrap(_ font: NimsFont) -> WrappedFont {
    if font.id == .zero, wrappedFonts.isEmpty {
      _ = wrap(
        .monospacedSystemFont(ofSize: 13, weight: .regular)
      )
    }

    return wrappedFonts[font.id]
  }

  private var wrappedFonts = [WrappedFont]()
}
