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

  /// Where each logical row lives in `storage`.
  ///
  /// Scrolling used to move the cells themselves, which is the whole grid for
  /// a one line scroll -- forty thousand of them on a large window at a small
  /// font, and the single largest cost in the reducer there. Rows are
  /// interchangeable blocks, so scrolling permutes this instead and the cells
  /// stay put. Every row access goes through it, which costs one extra load
  /// and keeps the single flat allocation the flat layout was chosen for.
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

  /// Scrolls `rows` by `offset` without touching a single cell.
  ///
  /// The rows that fall off the end are recycled to the other end, where the
  /// caller is about to overwrite them -- Neovim always sends the newly
  /// exposed lines straight after a scroll. That is the same contract the
  /// copying version had: it left the vacated rows holding stale content too.
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
  /// Compared by what the grid holds, not by where the rows happen to sit.
  /// Two grids showing the same thing are equal even if they scrolled there
  /// differently.
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
