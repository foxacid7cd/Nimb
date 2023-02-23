// SPDX-License-Identifier: MIT

import Foundation
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
}
