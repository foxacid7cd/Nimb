//
//  Font.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 18.12.2022.
//

import AppKit
import Collections
import Tagged

public struct Font: Sendable, Equatable {
  var id: ID
  public internal(set) var cellWidth: Double
  public internal(set) var cellHeight: Double

  init(
    id: Font.ID,
    cellWidth: Double,
    cellHeight: Double
  ) {
    self.id = id
    self.cellWidth = cellWidth
    self.cellHeight = cellHeight
  }

  typealias ID = Tagged<Font, Int>

  public var cellCGSize: CGSize {
    .init(width: cellWidth, height: cellHeight)
  }
}
