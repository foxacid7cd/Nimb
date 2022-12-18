//
//  Grid.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 17.12.2022.

import Foundation

struct TwoDimensionalArray<Element> {
  private var array: [Element]
  private var columnsCount: Int

  init(
    size: Size,
    repeatingElement: Element
  ) {
    self.init(
      size: size,
      elementAtPoint: { _ in
        repeatingElement
      }
    )
  }

  init(
    size: Size,
    elementAtPoint: (Point) -> Element
  ) {
    if size.columnsCount < 0 || size.rowsCount < 0 {
      preconditionFailure("Grid size must be non negative")
    }

    let elementsCount = size.columnsCount * size.rowsCount

    var accumulator = [Element]()
    for arrayIndex in (0..<elementsCount) {
      let (row, column) =
        arrayIndex
        .quotientAndRemainder(
          dividingBy: size.columnsCount
        )

      let element = elementAtPoint(
        .init(column: column, row: row)
      )
      accumulator.append(element)
    }

    array = accumulator
    columnsCount = size.columnsCount
  }

  var size: Size {
    .init(
      columnsCount: columnsCount,
      rowsCount: array.count / columnsCount
    )
  }

  subscript(row: Int) -> ArraySlice<Element> {
    get {
      array[arrayIndices(row: row)]
    }
    set {
      array[arrayIndices(row: row)] = newValue
    }
  }

  private func arrayIndices(row: Int) -> Range<Array.Index> {
    let startIndex = row * columnsCount
    let endIndex = startIndex + columnsCount

    return startIndex..<endIndex
  }
}

extension TwoDimensionalArray: Sendable where Element: Sendable {}

extension TwoDimensionalArray: Equatable where Element: Equatable {}
