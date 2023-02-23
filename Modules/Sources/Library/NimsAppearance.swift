// SPDX-License-Identifier: MIT

import AppKit
import IdentifiedCollections

public struct NimsAppearance: Equatable {
  public init(
    font: NimsFont,
    highlights: IdentifiedArrayOf<Highlight>,
    defaultForegroundColor: NimsColor,
    defaultBackgroundColor: NimsColor,
    defaultSpecialColor: NimsColor
  ) {
    self.font = font
    self.highlights = highlights
    self.defaultForegroundColor = defaultForegroundColor
    self.defaultBackgroundColor = defaultBackgroundColor
    self.defaultSpecialColor = defaultSpecialColor
  }

  public var font: NimsFont
  public var highlights: IdentifiedArrayOf<Highlight>
  public var defaultForegroundColor: NimsColor
  public var defaultBackgroundColor: NimsColor
  public var defaultSpecialColor: NimsColor

  public var cellWidth: Double {
    font.cellWidth
  }

  public var cellHeight: Double {
    font.cellHeight
  }

  public var cellSize: CGSize {
    font.cellSize
  }

  public static let defaultValue = Self(
    font: .init(.monospacedSystemFont(ofSize: 12, weight: .regular)),
    highlights: [],
    defaultForegroundColor: .init(rgb: 0xFFFFFF),
    defaultBackgroundColor: .init(rgb: 0x000000),
    defaultSpecialColor: .init(rgb: 0xFF0000)
  )
}
