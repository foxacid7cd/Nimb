// SPDX-License-Identifier: MIT

import Foundation

/// A fixed-size grid stored as one contiguous buffer.
///
/// This used to be `[[Element]]`, which for an 80x24 grid meant 24 separate
/// heap allocations, 24 independent copy-on-write checks per full-grid
/// mutation, and a double indirection on `subscript(point:)` — the hottest
/// read in the application.
///
/// Row access is deliberately not exposed as a mutable `[Element]`. Slices
/// keep their parent's indices, so handing one out invites off-by-one bugs
/// where a caller indexes a row slice with column numbers. The row operations
/// below all take column ranges and do the base arithmetic themselves.
public struct TwoDimensionalArray<Element> {
  /// Row-major, `rowsCount * columnsCount` elements.
  ///
  /// Public rather than private(set) so the hot accessors below can be
  /// @inlinable across the module boundary. Anything mutating it directly must
  /// preserve the element count — the grid is fixed size.
  public var storage: [Element]
  public var columnsCount: Int
  public var rowsCount: Int

  @inlinable
  public var size: IntegerSize {
    .init(columnsCount: columnsCount, rowsCount: rowsCount)
  }

  /// One slice per row, in order. The slices carry parent indices, so use them
  /// for iteration rather than indexing.
  @inlinable
  public var rowSlices: [ArraySlice<Element>] {
    (0 ..< rowsCount).map { rowSlice($0) }
  }

  @inlinable
  public init(
    size: IntegerSize,
    repeatingElement: Element,
  ) {
    precondition(size.columnsCount >= 0, "size.columnsCount must be non negative")
    precondition(size.rowsCount >= 0, "size.rowsCount must be non negative")

    columnsCount = size.columnsCount
    rowsCount = size.rowsCount
    storage = .init(
      repeating: repeatingElement,
      count: size.columnsCount * size.rowsCount,
    )
  }

  public init(
    size: IntegerSize,
    elementAtPoint: (IntegerPoint) -> Element,
  ) {
    precondition(size.columnsCount >= 0, "size.columnsCount must be non negative")
    precondition(size.rowsCount >= 0, "size.rowsCount must be non negative")

    columnsCount = size.columnsCount
    rowsCount = size.rowsCount
    storage = []
    storage.reserveCapacity(size.columnsCount * size.rowsCount)
    for rowIndex in 0 ..< size.rowsCount {
      for columnIndex in 0 ..< size.columnsCount {
        storage.append(
          elementAtPoint(.init(column: columnIndex, row: rowIndex)),
        )
      }
    }
  }

  @inlinable
  public subscript(point: IntegerPoint) -> Element {
    get {
      storage[point.row * columnsCount + point.column]
    }
    set {
      storage[point.row * columnsCount + point.column] = newValue
    }
    _modify {
      yield &storage[point.row * columnsCount + point.column]
    }
  }

  /// The elements of `row`, in order.
  @inlinable
  public func rowSlice(_ row: Int) -> ArraySlice<Element> {
    let start = row * columnsCount
    return storage[start ..< start + columnsCount]
  }

  /// The elements of `row` within `columns`, in order.
  @inlinable
  public func rowSlice(_ row: Int, columns: Range<Int>) -> ArraySlice<Element> {
    let start = row * columnsCount
    return storage[start + columns.lowerBound ..< start + columns.upperBound]
  }

  /// Replaces `columns` of `row`. `newElements` must have the same count as
  /// the range, since the grid is fixed size.
  @inlinable
  public mutating func replaceRow(
    _ row: Int,
    columns: Range<Int>,
    with newElements: some Collection<Element>,
  ) {
    let start = row * columnsCount
    storage.replaceSubrange(
      start + columns.lowerBound ..< start + columns.upperBound,
      with: newElements,
    )
  }

  /// Copies a whole row out of `source` into `destinationRow`.
  @inlinable
  public mutating func copyRow(
    _ sourceRow: Int,
    from source: Self,
    to destinationRow: Int,
  ) {
    replaceRow(
      destinationRow,
      columns: 0 ..< columnsCount,
      with: source.rowSlice(sourceRow),
    )
  }
}

extension TwoDimensionalArray: Sendable where Element: Sendable { }

extension TwoDimensionalArray: Equatable where Element: Equatable { }
