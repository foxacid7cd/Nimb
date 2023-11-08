// SPDX-License-Identifier: MIT

import AppKit
import Library

@PublicInit
public struct NimsFont: Sendable, Hashable {
  public init(_ appKit: NSFont) {
    let wrapped = FontBridge.shared.wrap(appKit)
    id = wrapped.index
  }

  public var id: Int = 0

  public var cellWidth: Double {
    wrapped.cellWidth
  }

  public var cellHeight: Double {
    wrapped.cellHeight
  }

  public var cellSize: CGSize {
    .init(width: cellWidth, height: cellHeight)
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

  private var wrapped: FontBridge.WrappedFont {
    FontBridge.shared.wrapped(for: self)
  }
}

final class FontBridge {
  init(dispatchQueue: DispatchQueue) {
    self.dispatchQueue = dispatchQueue

    let systemFont = NSFont.monospacedSystemFont(
      ofSize: NSFont.systemFontSize,
      weight: .regular
    )
    let wrapped = WrappedFont(index: 0, appKit: systemFont)
    array = [wrapped]
    indexes = [Key(systemFont): wrapped.index]
  }

  struct WrappedFont {
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

  static let shared = FontBridge(dispatchQueue: .init(
    label: "\(Bundle.main.bundleIdentifier!).FontBridge",
    attributes: .concurrent
  ))

  @discardableResult
  func wrap(_ appKit: NSFont) -> WrappedFont {
    let key = Key(appKit)
    if let existing = dispatchQueue.sync(execute: { indexes[key].map { array[$0] } }) {
      return existing
    }
    return dispatchQueue.sync(flags: .barrier) {
      let wrapped = WrappedFont(index: array.count, appKit: appKit)
      array.append(wrapped)
      indexes[key] = wrapped.index
      return wrapped
    }
  }

  func wrapped(for font: NimsFont) -> WrappedFont {
    dispatchQueue.sync { array[font.id] }
  }

  private let dispatchQueue: DispatchQueue
  private var array: [WrappedFont]
  private var indexes: [Key: Int]
}
