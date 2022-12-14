// Copyright © 2022 foxacid7cd. All rights reserved.

import Cocoa
import Collections
import OSLog

class MainView: NSView {
  init(store: Store) {
    self.store = store

    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(_ update: Store.Update) {}

  func gridResize(gridID: Int, gridSize: Size) {
    let gridView = gridViews[gridID] ?? {
      let new = GridView(store: store, gridID: gridID)
      self.gridViews[gridID] = new

      new.outerGridSize = self.outerGridSize
      return new
    }()

    gridView.isHidden = false
    gridView.gridSize = gridSize
    gridView.updateViewFrame()

    if gridView.superview == nil {
      addSubview(gridView)

      sortGridViews()
    }

    if gridID == 1 {
      outerGridSize = gridSize

      for gridView in gridViews.values {
        gridView.outerGridSize = gridSize

        gridView.updateViewFrame()
      }
    }
  }

  func gridLine(gridID: Int, origin: Point, cells: [_Cell]) {
    guard let gridView = gridViews[gridID] else {
      return
    }

    gridView.gridLine(origin: origin, cells: cells)
  }

  func gridClear(gridID: Int) {
    guard let gridView = gridViews[gridID] else {
      return
    }

    gridView.gridClear()
  }

  func gridDestroy(gridID: Int) {
    guard let gridView = gridViews.removeValue(forKey: gridID) else {
      return
    }

    gridView.removeFromSuperview()

    sortGridViews()
  }

  func winPos(gridID: Int, winRef: WinRef, gridFrame: Rectangle) {
    guard let gridView = gridViews[gridID] else {
      return
    }

    gridView.isHidden = false
    gridView.winPos = .init(
      winRef: winRef,
      gridFrame: gridFrame,
      zPositionWeight: winPosCallCounter
    )
    gridView.updateViewFrame()

    winPosCallCounter += 1

    sortGridViews()
  }

  func winFloatPos(
    gridID: Int,
    winRef _: WinRef,
    anchorType: String,
    anchorGridID: Int,
    anchorX: Double,
    anchorY: Double,
    focusable: Bool,
    zPosition: Int
  ) {
    guard
      let gridView = gridViews[gridID],
      let anchorGridView = gridViews[anchorGridID]
    else {
      return
    }

    gridView.isHidden = false
    gridView.winFloatPos = .init(
      anchorType: anchorType,
      anchorGridID: anchorGridID,
      anchorX: anchorX,
      anchorY: anchorY,
      focusable: focusable,
      zPosition: zPosition,
      zPositionWeight: winPosCallCounter,
      getAnchorGridOrigin: { [weak anchorGridView] in
        guard let anchorGridView else { return .init() }

        return anchorGridView.gridFrame.origin
      }
    )
    gridView.updateViewFrame()

    winPosCallCounter += 1

    sortGridViews()
  }

  func winHide(gridID: Int) {
    guard let gridView = gridViews[gridID] else {
      return
    }

    gridView.isHidden = true
  }

  func winClose(gridID: Int) {
    guard let gridView = gridViews[gridID] else {
      return
    }

    gridView.isHidden = true
    gridView.winPos = nil
    gridView.updateViewFrame()

    sortGridViews()
  }

  private var winPosCallCounter = 0
  private let store: Store
  private var gridViews = TreeDictionary<Int, GridView>()
  private var outerGridSize = Size()

  private func sortGridViews() {
    sortSubviews(compare, context: nil)
  }
}

func compare(
  firstView _: NSView,
  secondView _: NSView,
  context _: UnsafeMutableRawPointer?
)
  -> ComparisonResult {
  .orderedAscending
}

private class GridView: NSView {
  init(store: Store, gridID: Int) {
    self.store = store
    self.gridID = gridID

    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  struct WinPos {
    var winRef: WinRef
    var gridFrame: Rectangle

    var zPositionWeight: Int
  }

  struct WinFloatPos {
    var anchorType: String
    var anchorGridID: Int
    var anchorX: Double
    var anchorY: Double
    var focusable: Bool
    var zPosition: Int

    var zPositionWeight: Int
    var getAnchorGridOrigin: () -> Point
  }

  let gridID: Int
  var gridSize = Size()
  var outerGridSize = Size()
  var winPos: WinPos?
  var winFloatPos: WinFloatPos?

  override var isOpaque: Bool {
    true
  }

  var gridFrame: Rectangle {
    if let winFloatPos {
      return .init(
        origin: winFloatPos
          .getAnchorGridOrigin() + Point(x: Int(winFloatPos.anchorX), y: Int(winFloatPos.anchorY)),
        size: gridSize
      )
    }

    if let winPos {
      return .init(
        origin: .init(
          x: winPos.gridFrame.origin.x,
          y: outerGridSize.height - winPos.gridFrame.origin.y - winPos.gridFrame.size.height
        ),
        size: winPos.gridFrame.size
      )
    }

    return .init(size: gridSize)
  }

  var zPositionWeight: Int {
    if let winFloatPos {
      return 1_000_000_000 + winFloatPos.zPositionWeight
    }

    if let winPos {
      return 1_000_000_000 + winPos.zPositionWeight
    }

    return 0
  }

  override func draw(_: NSRect) {
//    let context = NSGraphicsContext.current!
//
//    context.saveGraphicsState()
//    defer { context.restoreGraphicsState() }
//
//    let rects = self.rectsBeingDrawn
//
//    context.cgContext.setFillColor(self._apperance.backgroundColor().cgColor)
//    context.cgContext.fill(rects)
//
//    var filteredDrawRuns = Deque<DrawRun>()
//    defer { self.drawRuns = filteredDrawRuns }
//
//    for drawRun in self.drawRuns {
//      guard rects.contains(where: { $0.contains(drawRun.rect) }) else {
//        filteredDrawRuns.append(drawRun)
//
//        continue
//      }
//      self.oldDrawRuns.append(drawRun)
//
//      for glyphRun in drawRun.glyphRuns {
//        context.cgContext.setShouldAntialias(false)
//        context.cgContext.setFillColor(glyphRun.backgroundColor.cgColor)
//
//        let backgroundGridRectangle = GridRectangle(
//          origin: .init(x: drawRun.gridOrigin.x + glyphRun.stringRange.location, y: drawRun.gridOrigin.y),
//          size: .init(width: glyphRun.stringRange.length + 1, height: 1)
//        )
//        let backgroundRect = (backgroundGridRectangle * self._.cellSize)
//
//        context.cgContext.fill([backgroundRect])
//
//        context.cgContext.setShouldAntialias(true)
//        context.cgContext.setFillColor(glyphRun.foregroundColor.cgColor)
//
//        CTFontDrawGlyphs(
//          glyphRun.font,
//          glyphRun.glyphs,
//          glyphRun.positionsWithOffset(
//            dx: drawRun.rect.origin.x,
//            dy: drawRun.rect.origin.y + self._apperance.cellSize.height - self._apperance.fonts.regular.ascender
//          ),
//          glyphRun.glyphs.count,
//          context.cgContext
//        )
//      }
//    }
  }

  func gridLine(origin _: Point, cells _: [_Cell]) {
//    let cellSize = self._apperance.cellSize
//
//    let origin = GridPoint(
//      x: origin.x,
//      y: self.gridFrame.size.height - origin.y - 1
//    )
//
//    let gridRectangle = GridRectangle(
//      origin: origin,
//      size: .init(
//        width: cells.count,
//        height: 1
//      )
//    )
//    let rect = gridRectangle * cellSize
//
//    let accumulator = NSMutableAttributedString()
//
//    let string = NSMutableString()
//    var previousCell = cells[0]
//
//    for (cellIndex, cell) in cells.enumerated() {
//      if cell.highlightID == previousCell.highlightID, cellIndex != cells.count - 1 {
//        string.append(cell.text)
//
//      } else {
//        let attributedString = NSAttributedString(
//          string: string as String,
//          attributes: self._apperance.stringAttributes(highlightID: previousCell.highlightID)
//        )
//        accumulator.append(attributedString)
//
//        string.setString(cell.text)
//      }
//
//      previousCell = cell
//    }
//
//    let drawRun = DrawRun.make(
//      gridOrigin: origin,
//      rect: rect,
//      attributedString: accumulator
//    )
//
//    self.drawRuns.append(drawRun)
//    setNeedsDisplay(rect)
  }

  func gridClear() {
    setNeedsDisplay(bounds)
  }

  func updateViewFrame() {
//    self.frame = self.gridFrame * self._appearance.font.cellSize
  }

  private let store: Store
  private var drawRuns = Deque<DrawRun>()
  private var oldDrawRuns = Deque<DrawRun>()
}

struct _Cell {
  var text = " "
  var highlightID: Int?
}
