// SPDX-License-Identifier: MIT

import AppKit
import Collections
import CustomDump
import Queue

public class GridsView: NSView, CALayerDelegate {
  private enum MouseButton: String, Sendable {
    case left
    case right
    case middle
  }

  private enum MouseAction: String, Sendable {
    case press
    case drag
    case release
  }

  override public var intrinsicContentSize: NSSize {
    guard let font, let outerGridSize else {
      return .zero
    }
    return outerGridSize * font.cellSize
  }

  private let store: Store
  private let remoteRenderer: RendererProtocol
  private var arrangedGridLayers = IntKeyedDictionary<GridLayer>()
  private var leftMouseInteractionTarget: GridLayer?
  private var rightMouseInteractionTarget: GridLayer?
  private var otherMouseInteractionTarget: GridLayer?
  private var font: Font?
  private var outerGridSize: IntegerSize?
  private var gridsHierarchy = GridsHierarchy()
  private let rendererQueue = AsyncQueue()

  public var upsideDownTransform: CGAffineTransform {
    guard let font, let outerGridSize else {
      return .identity
    }
    return .init(scaleX: 1, y: -1)
      .translatedBy(
        x: 0,
        y: -Double(outerGridSize.rowsCount) * font.cellHeight
      )
  }

  init(store: Store, remoteRenderer: RendererProtocol) {
    self.store = store
    self.remoteRenderer = remoteRenderer
    super.init(frame: .init())

    wantsLayer = true
    layer!.masksToBounds = true
    layer!.delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func updateTrackingAreas() {
    super.updateTrackingAreas()

    for trackingArea in trackingAreas {
      removeTrackingArea(trackingArea)
    }

    addTrackingArea(.init(
      rect: bounds,
      options: [.inVisibleRect, .activeInKeyWindow, .mouseMoved],
      owner: self,
      userInfo: nil
    ))
  }

  override public func viewWillMove(toWindow newWindow: NSWindow?) {
    super.viewWillMove(toWindow: newWindow)

    if let newWindow {
      let contentsScale = newWindow.backingScaleFactor

      layer!.contentsScale = contentsScale

      for gridLayer in arrangedGridLayers.values {
        if gridLayer.contentsScale != contentsScale {
          gridLayer.contentsScale = contentsScale
        }
      }
    }
  }

  override public func mouseMoved(with event: NSEvent) {
    let location = layer!.convert(event.locationInWindow, from: nil)
    if let gridLayer = layer!.hitTest(location) as? GridLayer {
      gridLayer.reportMouseMove(for: event)
    }
  }

  override public func mouseDown(with event: NSEvent) {
    report(mouseButton: .left, action: .press, with: event)
  }

  override public func mouseDragged(with event: NSEvent) {
    report(mouseButton: .left, action: .drag, with: event)
  }

  override public func mouseUp(with event: NSEvent) {
    report(mouseButton: .left, action: .release, with: event)
  }

  override public func rightMouseDown(with event: NSEvent) {
    report(mouseButton: .right, action: .press, with: event)
  }

  override public func rightMouseDragged(with event: NSEvent) {
    report(mouseButton: .right, action: .drag, with: event)
  }

  override public func rightMouseUp(with event: NSEvent) {
    report(mouseButton: .right, action: .release, with: event)
  }

  override public func otherMouseDown(with event: NSEvent) {
    report(mouseButton: .middle, action: .press, with: event)
  }

  override public func otherMouseDragged(with event: NSEvent) {
    report(mouseButton: .middle, action: .drag, with: event)
  }

  override public func otherMouseUp(with event: NSEvent) {
    report(mouseButton: .middle, action: .release, with: event)
  }

  override public func scrollWheel(with event: NSEvent) {
    let location = layer!.convert(event.locationInWindow, from: nil)
    if let gridLayer = layer!.hitTest(location) as? GridLayer {
      gridLayer.scrollWheel(with: event)
    }
  }

  public nonisolated func action(for layer: CALayer, forKey event: String) -> (any CAAction)? {
    NSNull()
  }

//  public func render() {
//    for gridID in updates.destroyedGridIDs {
//      let layer = arrangedGridLayer(forGridWithID: gridID)
//      layer.isHidden = true
//    }
//
//    let updatedLayoutGridIDs =
//      if updates.isFontUpdated {
//        Set(state.grids.keys)
//
//      } else {
//        updates.updatedLayoutGridIDs
//      }
//
//    for gridID in updatedLayoutGridIDs {
//      guard let grid = state.grids[gridID] else {
//        continue
//      }
//
//      let gridLayer = arrangedGridLayer(forGridWithID: gridID)
//      gridLayer.isHidden = grid.isHidden
//
//      if gridID == Grid.OuterID {
//        invalidateIntrinsicContentSize()
//      } else if let associatedWindow = grid.associatedWindow {
//        switch associatedWindow {
//        case .external:
//          gridLayer.isHidden = true
//
//        default:
//          break
//        }
//      }
//    }
//
//    if !updatedLayoutGridIDs.isEmpty || updates.isGridsHierarchyUpdated {
//      let upsideDownTransform = upsideDownTransform
//
//      state.walkingGridFrames { id, frame, zPosition in
//        guard let gridLayer = arrangedGridLayers[id] else {
//          logger.warning("walkingGridFrames: gridLayer with id \(id) not found")
//          return
//        }
//        guard !gridLayer.isHidden else {
//          return
//        }
//        if updatedLayoutGridIDs.contains(id) {
//          gridLayer.frame = frame.applying(upsideDownTransform)
//        }
//        if updates.isGridsHierarchyUpdated, gridLayer.zPosition != zPosition {
//          gridLayer.zPosition = zPosition
//        }
//      }
//    }
//
//    renderChildren(
//      arrangedGridLayers.values
//        .lazy
//        .filter { !$0.isHidden }
//    )
//  }

  public func windowFrame(
    forGridID gridID: Grid.ID,
    gridFrame: IntegerRectangle
  )
    -> CGRect?
  {
    nil
//    arrangedGridLayers[gridID]?.windowFrame(forGridFrame: gridFrame)
  }

  public func arrangedGridLayer(forGridWithID id: Grid.ID) -> GridLayer {
    if let gridLayer = arrangedGridLayers[id] {
      return gridLayer

    } else {
      let gridLayer = GridLayer(
        store: store,
        remoteRenderer: remoteRenderer,
        gridID: id
      )
      gridLayer.contentsScale = layer!.contentsScale
      gridLayer.font = font
      layer!.addSublayer(gridLayer)
      arrangedGridLayers[id] = gridLayer
      return gridLayer
    }
  }

  public func handle(font: Font) {
    self.font = font
    invalidateIntrinsicContentSize()

    for gridLayer in arrangedGridLayers.values {
      gridLayer.font = font
    }
  }

  public func handle(uiEvents: [UIEvent]) {
    var shouldWalkGridFrames = false

    for uiEvent in uiEvents {
      switch uiEvent {
      case let .gridResize(gridID, width, height):
        let size = IntegerSize(columnsCount: width, rowsCount: height)

        if gridID == Grid.OuterID {
          outerGridSize = size
          invalidateIntrinsicContentSize()
        }
        let gridLayer = arrangedGridLayer(forGridWithID: gridID)
        gridLayer.handleResize(gridSize: size)
        gridLayer.lastHandledGridSize = size
        gridsHierarchy.addNode(id: gridID, parent: Grid.OuterID)
        shouldWalkGridFrames = true

      case let .gridDestroy(gridID):
        if let gridLayer = arrangedGridLayers[gridID] {
          gridLayer.isHidden = true
        }
        shouldWalkGridFrames = true

      case let .winPos(
        gridID,
        windowID,
        startrow,
        startcol,
        width,
        height
      ):
        let origin = IntegerPoint(column: startrow, row: startcol)
        let size = IntegerSize(columnsCount: width, rowsCount: height)

        let gridLayer = arrangedGridLayer(forGridWithID: gridID)
        gridLayer.associatedWindow = .plain(.init(id: windowID, origin: origin))
        gridLayer.handleResize(gridSize: size)
        gridLayer.lastHandledGridSize = size
        gridLayer.isHidden = false
        gridsHierarchy.addNode(id: gridID, parent: Grid.OuterID)

        shouldWalkGridFrames = true

      case let .winFloatPos(
        gridID,
        windowID,
        anchor,
        anchorGridID,
        anchorRow,
        anchorCol,
        focusable,
        zindex
      ):
        let anchor = FloatingWindow.Anchor(rawValue: anchor)!

        let gridLayer = arrangedGridLayer(forGridWithID: gridID)
        gridLayer.associatedWindow = .floating(
          .init(
            id: windowID,
            anchor: anchor,
            anchorGridID: anchorGridID,
            anchorRow: anchorRow,
            anchorColumn: anchorCol,
            isFocusable: focusable,
            zIndex: zindex
          )
        )
        gridsHierarchy.addNode(id: gridID, parent: anchorGridID)

        shouldWalkGridFrames = true

      case let .winHide(gridID):
        let gridLayer = arrangedGridLayer(forGridWithID: gridID)
        gridLayer.isHidden = true

        shouldWalkGridFrames = true

      case let .winClose(gridID):
        let gridLayer = arrangedGridLayer(forGridWithID: gridID)
        gridLayer.associatedWindow = nil
        gridsHierarchy.removeNode(id: gridID)

        shouldWalkGridFrames = true

      case let .gridLine(gridID, row, colStart, data, wrap):
        let gridLayer = arrangedGridLayer(forGridWithID: gridID)
        gridLayer.handleLine(row: row, originColumn: colStart, data: data, wrap: wrap)

      case let .gridScroll(
        gridID,
        top,
        bot,
        left,
        right,
        rows,
        cols
      ):
        let rectangle = IntegerRectangle(
          origin: .init(column: left, row: top),
          size: .init(columnsCount: right - left, rowsCount: bot - top)
        )
        let offset = IntegerSize(
          columnsCount: cols,
          rowsCount: rows
        )
        let gridLayer = arrangedGridLayer(forGridWithID: gridID)
        gridLayer.handleScroll(rectangle: rectangle, offset: offset)

      case let .gridClear(gridID):
        let gridLayer = arrangedGridLayer(forGridWithID: gridID)
        gridLayer.handleClear()

      case .flush:
        for gridLayer in arrangedGridLayers.values {
          gridLayer.handleFlush()
        }

      default:
        break
      }
    }

    if shouldWalkGridFrames {
      walkingGridFrames { id, frame, zPosition in
        let gridLayer = arrangedGridLayer(forGridWithID: id)
        gridLayer.frame = frame.applying(upsideDownTransform)
        gridLayer.zPosition = zPosition
      }
    }
  }

  private func report(
    mouseButton: MouseButton,
    action: MouseAction,
    with event: NSEvent
  ) {
    var gridLayer: GridLayer?

    switch action {
    case .press:
      let location = layer!.convert(event.locationInWindow, from: nil)
      gridLayer = layer!.hitTest(location) as? GridLayer
      if let gridLayer {
        switch mouseButton {
        case .left:
          leftMouseInteractionTarget = gridLayer
        case .right:
          rightMouseInteractionTarget = gridLayer
        case .middle:
          otherMouseInteractionTarget = gridLayer
        }
      }

    case .drag:
      gridLayer =
        switch mouseButton {
        case .left:
          leftMouseInteractionTarget
        case .right:
          rightMouseInteractionTarget
        case .middle:
          otherMouseInteractionTarget
        }

    case .release:
      switch mouseButton {
      case .left:
        gridLayer = leftMouseInteractionTarget
        leftMouseInteractionTarget = nil

      case .right:
        gridLayer = rightMouseInteractionTarget
        rightMouseInteractionTarget = nil

      case .middle:
        gridLayer = otherMouseInteractionTarget
        otherMouseInteractionTarget = nil
      }
    }

    if let gridLayer {
      gridLayer.report(
        mouseButton: mouseButton.rawValue,
        action: action.rawValue,
        with: event
      )
    }
  }

  private func walkingGridFrames(_ body: (_ id: Grid.ID, _ frame: CGRect, _ zPosition: Double) throws -> Void) rethrows {
    guard let font else {
      return
    }
    var queue: Deque<(id: Int, depth: Int)> = [
      (id: Grid.OuterID, depth: 0),
    ]
    var positionsInParent = IntKeyedDictionary<CGPoint>()
    var nodesCount = 0
    while let (id, depth) = queue.popFirst() {
      let gridLayer = arrangedGridLayer(forGridWithID: id)

      if id == Grid.OuterID {
        positionsInParent[id] = .init()

      } else if let associatedWindow = gridLayer.associatedWindow {
        switch associatedWindow {
        case let .plain(window):
          positionsInParent[id] = window.origin * font.cellSize

        case let .floating(floatingWindow):
          let anchorGridLayer = arrangedGridLayer(
            forGridWithID: floatingWindow.anchorGridID
          )

          var gridColumn: Double = floatingWindow.anchorColumn
          var gridRow: Double = floatingWindow.anchorRow
          switch floatingWindow.anchor {
          case .northWest:
            break

          case .northEast:
            gridColumn -= Double(
              anchorGridLayer.lastHandledGridSize!.columnsCount
            )

          case .southWest:
            gridRow -= Double(anchorGridLayer.lastHandledGridSize!.rowsCount)

          case .southEast:
            gridColumn -= Double(anchorGridLayer.lastHandledGridSize!.columnsCount)
            gridRow -= Double(anchorGridLayer.lastHandledGridSize!.rowsCount)
          }
          positionsInParent[id] = .init(
            x: gridColumn * font.cellWidth,
            y: gridRow * font.cellHeight
          ) + positionsInParent[anchorGridLayer.gridID]!

        case .external:
          positionsInParent[id] = .init()
        }

      } else {
        positionsInParent[id] = .init()
      }

      let frame = CGRect(
        origin: positionsInParent[id]!,
        size: gridLayer.lastHandledGridSize! * font.cellSize
      )

      try body(id, frame, Double(1_000_000 * depth + nodesCount * 1000))
      let nextDepth = depth + 1
      queue
        .append(
          contentsOf: gridsHierarchy.allNodes[id]!
            .children
            .map { (id: $0, depth: nextDepth) }
        )
      nodesCount += 1
    }
  }

  private func point(for event: NSEvent) -> IntegerPoint {
    guard let font else {
      return .init()
    }
    let upsideDownLocation = convert(event.locationInWindow, from: nil)
      .applying(upsideDownTransform)
    return .init(
      column: Int(upsideDownLocation.x / font.cellWidth),
      row: Int(upsideDownLocation.y / font.cellHeight)
    )
  }
}
