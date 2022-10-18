//
//  Grid.swift
//  Library
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public struct Grid<Element> {
  public init(repeating element: Element, rowsCount: Int, columnsCount: Int) {
    assert(rowsCount > 0)
    assert(columnsCount > 0)
    let row = [Element](repeating: element, count: columnsCount)
    self.rows = .init(repeating: row, count: rowsCount)
  }

  public private(set) var rows: [[Element]]

  public var rowsCount: Int {
    self.rows.count
  }

  public var columnsCount: Int {
    self.rows[0].count
  }

  public subscript(row: Int, column: Int) -> Element {
    get {
      self.rows[row][column]
    }
    set(newValue) {
      self.rows[row][column] = newValue
    }
  }
}
