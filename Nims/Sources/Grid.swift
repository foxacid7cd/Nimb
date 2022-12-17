//
//  Grid.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 17.12.2022.
//

import Foundation

struct Grid<Element> {
  init(
    sizr: GridSize,
    repeatingElement: Element
  ) {
    self.init(
      size: sizr,
      elementAtPosition: { _ in
        repeatingElement
      }
    )
  }

  init(
    size: GridSize,
    elementAtPosition: (GridPoint) -> Element
  ) {
    if size.columnsCount < 0 || size.rowsCount < 0 {
      preconditionFailure("Grid size must be non negative")
    }

    let elementsCount = size.columnsCount * size.rowsCount

    var accumulator = [Element]()
    for arrayIndex in (0..<elementsCount) {
      let (row, column) = arrayIndex
      .quotientAndRemainder(
        dividingBy: size.columnsCount
      )

      let element = elementAtPosition(
        .init(column: column, row: row)
      )
      accumulator.append(element)
    }

    storage = .init(
      array: accumulator,
      columnsCount: size.columnsCount
    )
  }

  private var storage: Storage

  private struct Storage {
    var array = [Element]()
    var columnsCount: Int
  }
}

extension Grid: Sendable where Element: Sendable {}

struct GridSize: Sendable, Equatable {
  var columnsCount: Int
  var rowsCount: Int
}

struct GridPoint: Sendable, Equatable {
  var column: Int
  var row: Int
}
