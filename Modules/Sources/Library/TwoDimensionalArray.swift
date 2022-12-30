// SPDX-License-Identifier: MIT

import Foundation

public struct TwoDimensionalArray<Element> {
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
    for arrayIndex in 0..<elementsCount {
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

  public struct RowsView: RandomAccessCollection {
    public var startIndex: Int {
      0
    }

    public var endIndex: Int {
      target.rowsCount
    }

    public subscript(row: Int) -> ArraySlice<Element> {
      get {
        target.elements[elementsIndices(for: row)]
      }
      set {
        target.elements[elementsIndices(for: row)] = newValue
      }
    }

    var target: TwoDimensionalArray<Element>

    private func elementsIndices(for row: Int) -> Range<Int> {
      let lower = target.columnsCount * row
      let upper = lower + target.columnsCount
      return lower..<upper
    }
  }

  public internal(set) var elements: [Element]
  public internal(set) var columnsCount: Int

  public var rowsCount: Int {
    elements.count / columnsCount
  }

  public var size: IntegerSize {
    .init(
      columnsCount: columnsCount,
      rowsCount: rowsCount
    )
  }

  public var rows: RowsView {
    get {
      .init(target: self)
    }
    set {
      self = newValue.target
    }
  }

  public subscript(point: IntegerPoint) -> Element {
    get {
      elements[elementsIndex(for: point)]
    }
    set {
      elements[elementsIndex(for: point)] = newValue
    }
  }

  private func elementsIndex(for point: IntegerPoint) -> Int {
    columnsCount * point.row + point.column
  }
}

extension TwoDimensionalArray: Sendable where Element: Sendable {}

extension TwoDimensionalArray: Equatable where Element: Equatable {}
