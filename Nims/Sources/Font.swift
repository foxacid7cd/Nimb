// SPDX-License-Identifier: MIT

import AppKit
import Library

public struct Font: Sendable, Hashable {
  @MainActor
  public init(_ appKit: NSFont) {
    wrapped = FontBridge.shared.wrap(appKit)
  }

  @MainActor
  public init() {
    wrapped = FontBridge.shared.defaultWrappedFont
  }

  public var id: Int {
    wrapped.index
  }

  public var cellSize: CGSize {
    .init(width: wrapped.cellWidth, height: wrapped.cellHeight)
  }

  public var cellWidth: Double {
    wrapped.cellWidth
  }

  public var cellHeight: Double {
    wrapped.cellHeight
  }

  public static func == (lhs: Font, rhs: Font) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public func appKit(isBold: Bool = false, isItalic: Bool = false) -> NSFont {
    if isBold, isItalic {
      wrapped.boldItalic
    } else if isBold {
      wrapped.bold
    } else if isItalic {
      wrapped.italic
    } else {
      wrapped.regular
    }
  }

  private var wrapped: FontBridge.WrappedFont
}

@MainActor
final class FontBridge {
  init() {
    let systemFont = NSFont.monospacedSystemFont(
      ofSize: NSFont.systemFontSize,
      weight: .regular
    )
    let wrapped = WrappedFont(index: 0, appKit: systemFont)
    array = [wrapped]
    indexes = [Key(systemFont): wrapped.index]
  }

  struct WrappedFont: @unchecked Sendable {
    init(index: Int, appKit: NSFont) {
      self.index = index

      var regular = appKit
      let fontManager = NSFontManager.shared
      if fontManager.traits(of: regular).contains(.boldFontMask) {
        regular = fontManager.convert(regular, toNotHaveTrait: .boldFontMask)
      }
      if fontManager.traits(of: regular).contains(.italicFontMask) {
        regular = fontManager.convert(regular, toNotHaveTrait: .italicFontMask)
      }
      self.regular = regular

      bold = fontManager.convert(appKit, toHaveTrait: .boldFontMask)
      italic = fontManager.convert(appKit, toHaveTrait: .italicFontMask)
      boldItalic = fontManager.convert(bold, toHaveTrait: .italicFontMask)

      cellWidth = appKit.makeCellWidth()
      cellHeight = appKit.makeCellHeight()
    }

    var index: Int
    var regular: NSFont
    var bold: NSFont
    var italic: NSFont
    var boldItalic: NSFont
    var cellWidth: Double
    var cellHeight: Double
  }

  struct Key: Hashable {
    init(_ appKit: NSFont) {
      familyName = appKit.familyName ?? appKit.fontName
      size = appKit.pointSize
    }

    var familyName: String
    var size: Double
  }

  static let shared = FontBridge()

  var defaultWrappedFont: WrappedFont {
    array[0]
  }

  func wrap(_ appKit: NSFont) -> WrappedFont {
    let key = Key(appKit)
    if let existing = indexes[key].map({ array[$0] }) {
      return existing
    }
    let wrapped = WrappedFont(index: array.count, appKit: appKit)
    array.append(wrapped)
    indexes[key] = wrapped.index
    return wrapped
  }

  private var array: [WrappedFont]
  private var indexes: [Key: Int]
}
