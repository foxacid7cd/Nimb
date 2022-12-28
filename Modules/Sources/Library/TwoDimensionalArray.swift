//
//  TwoDimensionalArray.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 17.12.2022.

import Foundation

public struct TwoDimensionalArray<Element> {
  var elements: [Element]
  public internal(set) var columnsCount: Int

  init(elements: [Element], columnsCount: Int) {
    self.elements = elements
    self.columnsCount = columnsCount
  }

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

    elements = accumulator
    columnsCount = size.columnsCount
  }

  public var rowsCount: Int {
    elements.count / columnsCount
  }

  public var size: IntegerSize {
    .init(
      columnsCount: columnsCount,
      rowsCount: rowsCount
    )
  }

  public subscript(row: Int) -> ArraySlice<Element> {
    get {
      elements[arrayIndices(row: row)]
    }
    set {
      elements[arrayIndices(row: row)] = newValue
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
