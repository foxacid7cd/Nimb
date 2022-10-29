//
//  SubGrid.swift
//  Library
//
//  Created by Yevhenii Matviienko on 24.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation

public class SubGrid<Element>: GridProtocol {
  init(grid: Grid<Element>, rectangle: GridRectangle) {
    self.grid = grid
    self.rectangle = rectangle
  }

  public var size: GridSize {
    self.rectangle.size
  }

  public subscript(index: GridPoint) -> Element {
    self.grid[index + self.rectangle.origin]
  }

  private let grid: Grid<Element>
  private let rectangle: GridRectangle
}

public extension Grid {
  init(_ subGrid: SubGrid<Element>) {
    self.init(size: subGrid.size) { index in
      subGrid[index]
    }
  }
}
