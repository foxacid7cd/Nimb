// SPDX-License-Identifier: MIT

import Foundation
import IdentifiedCollections

public struct NimsAppearance: Equatable {
  public init(
    font: NimsFont,
    cellWidth: Double,
    cellHeight: Double,
    highlights: IdentifiedArrayOf<Highlight>,
    defaultForegroundColor: NimsColor,
    defaultBackgroundColor: NimsColor,
    defaultSpecialColor: NimsColor
  ) {
    self.font = font
    self.cellWidth = cellWidth
    self.cellHeight = cellHeight
    self.highlights = highlights
    self.defaultForegroundColor = defaultForegroundColor
    self.defaultBackgroundColor = defaultBackgroundColor
    self.defaultSpecialColor = defaultSpecialColor
  }

  public var font: NimsFont
  public var cellWidth: Double
  public var cellHeight: Double
  public var highlights: IdentifiedArrayOf<Highlight>
  public var defaultForegroundColor: NimsColor
  public var defaultBackgroundColor: NimsColor
  public var defaultSpecialColor: NimsColor

  public var cellSize: CGSize {
    .init(width: cellWidth, height: cellHeight)
  }
}
