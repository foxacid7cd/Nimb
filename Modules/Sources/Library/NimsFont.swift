// SPDX-License-Identifier: MIT

import AppKit
import Tagged

public struct NimsFont: Sendable, Equatable {
  public init(id: ID) {
    self.id = id
  }

  public typealias ID = Tagged<Self, Int>

  public var id: ID

  public init(_ appKit: NSFont) {
    self = FontBridge.shared.wrap(appKit)
  }

  public var appKit: (regular: NSFont, bold: NSFont, italic: NSFont, boldItalic: NSFont) {
    FontBridge.shared.unwrap(self)
  }

  public func appKit(isBold: Bool, isItalic: Bool) -> NSFont {
    let (regular, bold, italic, boldItalic) = appKit

    if isBold, isItalic {
      return boldItalic

    } else if isBold {
      return bold

    } else if isItalic {
      return italic

    } else {
      return regular
    }
  }
}

final class FontBridge {
  static let shared = FontBridge()

  func wrap(_ appKit: NSFont) -> NimsFont {
    let bold = NSFontManager.shared.convert(appKit, toHaveTrait: .boldFontMask)
    let italic = NSFontManager.shared.convert(appKit, toHaveTrait: .italicFontMask)
    let boldItalic = NSFontManager.shared.convert(bold, toHaveTrait: .italicFontMask)

    return dispatchQueue.sync(flags: [.barrier]) {
      let font = NimsFont(id: .init(wrapped.count))
      wrapped.append((appKit, bold, italic, boldItalic))
      return font
    }
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
