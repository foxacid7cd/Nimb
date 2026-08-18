// SPDX-License-Identifier: MIT

import AppKit
import CoreText
import NimbCore

public struct Font: Sendable, Hashable {
  private var wrapped: FontBridge.WrappedFont

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

  @MainActor
  public init(_ appKit: NSFont) {
    wrapped = FontBridge.shared.wrap(appKit)
  }

  @MainActor
  public init() {
    wrapped = FontBridge.shared.defaultWrappedFont
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

  /// The CoreText attribute dictionary for one trait combination, built once
  /// per font rather than per shaped run.
  ///
  /// DrawRun used to hand `[.font: nsFont]` to NSAttributedString, which
  /// bridges a fresh Swift Dictionary into an NSDictionary on every miss of
  /// the draw run cache — and most shaped runs are misses, averaging under
  /// four cells each.
  public func attributes(isBold: Bool = false, isItalic: Bool = false) -> CFDictionary {
    wrapped.attributes[FontBridge.WrappedFont.variantIndex(isBold: isBold, isItalic: isItalic)]
  }
}

@MainActor
final class FontBridge {
  /// Unchecked for the same reason as GlyphRun: it holds NSFont values,
  /// which are immutable but unannotated.
  struct WrappedFont: @unchecked Sendable {
    var index: Int
    var regular: NSFont
    var bold: NSFont
    var italic: NSFont
    var boldItalic: NSFont
    var cellWidth: Double
    var cellHeight: Double
    /// Indexed by `variantIndex`, so the four trait combinations line up with
    /// the four fonts above.
    var attributes: [CFDictionary]

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

      attributes = [regular, bold, italic, boldItalic].map { font in
        [kCTFontAttributeName as String: font] as CFDictionary
      }
    }

    static func variantIndex(isBold: Bool, isItalic: Bool) -> Int {
      (isBold ? 1 : 0) | (isItalic ? 2 : 0)
    }
  }

  struct Key: Hashable {
    var familyName: String
    var size: Double

    init(_ appKit: NSFont) {
      familyName = appKit.familyName ?? appKit.fontName
      size = appKit.pointSize
    }
  }

  static let shared = FontBridge()

  private var array: [WrappedFont]
  private var indexes: [Key: Int]

  var defaultWrappedFont: WrappedFont {
    array[0]
  }

  init() {
    let systemFont = NSFont.monospacedSystemFont(
      ofSize: NSFont.systemFontSize,
      weight: .regular,
    )
    let wrapped = WrappedFont(index: 0, appKit: systemFont)
    array = [wrapped]
    indexes = [Key(systemFont): wrapped.index]
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
}
