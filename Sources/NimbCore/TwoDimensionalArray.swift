// SPDX-License-Identifier: MIT

import Foundation

/// A fixed-size grid stored as one contiguous buffer, so a full-grid mutation
/// is one copy-on-write check. Rows are addressed by column range, not sliced.
public struct TwoDimensionalArray<Element> {
  /// Row-major, `rowsCount * columnsCount` elements. Public so the accessors
  /// below can be @inlinable; a direct mutation must preserve the count.
  public var storage: [Element]
  public var columnsCount: Int
  public var rowsCount: Int

  /// Where each logical row lives in `storage`. Scrolling permutes this rather
  /// than moving cells, at the cost of one extra load per row access.
  public var rowOrder: [Int]

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
    rowOrder = .init(0 ..< size.rowsCount)
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
    rowOrder = .init(0 ..< size.rowsCount)
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

  /// Where `row` starts in `storage`.
  @inlinable
  public func rowStart(_ row: Int) -> Int {
    rowOrder[row] * columnsCount
  }

  @inlinable
  public subscript(point: IntegerPoint) -> Element {
    get {
      storage[rowStart(point.row) + point.column]
    }
    set {
      storage[rowStart(point.row) + point.column] = newValue
    }
    _modify {
      yield &storage[rowStart(point.row) + point.column]
    }
  }

  /// The elements of `row`, in order.
  @inlinable
  public func rowSlice(_ row: Int) -> ArraySlice<Element> {
    let start = rowStart(row)
    return storage[start ..< start + columnsCount]
  }

  /// The elements of `row` within `columns`, in order.
  @inlinable
  public func rowSlice(_ row: Int, columns: Range<Int>) -> ArraySlice<Element> {
    let start = rowStart(row)
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
    let start = rowStart(row)
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

  /// Scrolls `rows` by `offset` without touching a cell. Rows falling off the
  /// end are recycled holding stale content, which the caller then overwrites.
  @inlinable
  public mutating func rotateRows(_ rows: Range<Int>, by offset: Int) {
    guard !rows.isEmpty, offset != 0, rows.count > abs(offset) else {
      return
    }
    let order = Array(rowOrder[rows])
    let shift = ((offset % order.count) + order.count) % order.count
    rowOrder.replaceSubrange(rows, with: order[shift...] + order[..<shift])
  }
}

extension TwoDimensionalArray: Sendable where Element: Sendable { }

extension TwoDimensionalArray: Equatable where Element: Equatable {
  /// Compared by what the grid holds, not where the rows sit, so two grids
  /// showing the same thing are equal however they scrolled there.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    guard lhs.columnsCount == rhs.columnsCount, lhs.rowsCount == rhs.rowsCount else {
      return false
    }
    for row in 0 ..< lhs.rowsCount where lhs.rowSlice(row) != rhs.rowSlice(row) {
      return false
    }
    return true
  }
}
