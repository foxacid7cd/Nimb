//
//  SubGrid.swift
//  Library
//
//  Created by Yevhenii Matviienko on 24.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation

public struct SubGrid<Element>: GridProtocol {
  init(size: GridSize, rows: Rows) {
    self.size = size
    self.rows = rows
  }

  public typealias Rows = LazyMapSequence<ArraySlice<[Element]>, ArraySlice<Element>>

  public let size: GridSize

  public subscript(index: GridPoint) -> Element {
    self.rows[index.row][index.column]
  }

  private let rows: Rows
}
