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

  public struct Index {
    public init(row: Int, column: Int) {
      self.row = row
      self.column = column
    }

    public var row: Int
    public var column: Int
  }

  public private(set) var rows: [[Element]]

  public var rowsCount: Int {
    self.rows.count
  }

  public var columnsCount: Int {
    self.rows[0].count
  }

  public subscript(index: Index) -> Element {
    get {
      self.rows[index.row][index.column]
    }
    set(newValue) {
      self.rows[index.row][index.column] = newValue
    }
  }
}
