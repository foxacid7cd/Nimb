// SPDX-License-Identifier: MIT

import Foundation

public struct TwoDimensionalArray<Element> {
  public var rows: [[Element]]
  public internal(set) var columnsCount: Int

  @inlinable
  public var size: IntegerSize {
    .init(
      columnsCount: columnsCount,
      rowsCount: rows.count
    )
  }

  @inlinable
  public var rowsCount: Int {
    rows.count
  }

  @inlinable
  public init(
    size: IntegerSize,
    repeatingElement: Element
  ) {
    self.init(
      size: size,
      elementAtPoint: { _ in
        repeatingElement
      }
    )
  }

  public init(
    size: IntegerSize,
    elementAtPoint: (IntegerPoint) -> Element
  ) {
    if size.columnsCount < 0 {
      preconditionFailure("size.columnsCount must be non negative")
    }
    if size.rowsCount < 0 {
      preconditionFailure("size.rowsCount must be non negative")
    }

    var rows = [[Element]]()
    for rowIndex in 0 ..< size.rowsCount {
      var row = [Element]()
      for columnIndex in 0 ..< size.columnsCount {
        let element = elementAtPoint(
          .init(column: columnIndex, row: rowIndex)
        )
        row.append(element)
      }
      rows.append(row)
    }

    self.rows = rows
    columnsCount = size.columnsCount
  }

  @inlinable
  public subscript(point: IntegerPoint) -> Element {
    get {
      rows[point.row][point.column]
    }
    set {
      rows[point.row][point.column] = newValue
    }
  }
}

extension TwoDimensionalArray: Sendable where Element: Sendable { }

extension TwoDimensionalArray: Equatable where Element: Equatable { }
