// SPDX-License-Identifier: MIT

import AppKit
import Collections
import Tagged

public struct Font: Sendable, Equatable {
  init(
    id: Font.ID,
    cellWidth: Double,
    cellHeight: Double
  ) {
    self.id = id
    self.cellWidth = cellWidth
    self.cellHeight = cellHeight
  }

  public internal(set) var cellWidth: Double
  public internal(set) var cellHeight: Double

  typealias ID = Tagged<Font, Int>

  var id: ID
}
