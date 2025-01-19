// SPDX-License-Identifier: MIT

import AppKit
import Collections
import CustomDump

public class GridsView: NSView, CALayerDelegate, Rendering {
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
    guard isRendered else {
      return .zero
    }
    guard let outerGrid = state.outerGrid else {
      return .zero
    }
    return outerGrid.size * state.font.cellSize
  }

  private var store: Store
  private var arrangedGridLayers = IntKeyedDictionary<GridLayer>()
  private var leftMouseInteractionTarget: GridLayer?
  private var rightMouseInteractionTarget: GridLayer?
  private var otherMouseInteractionTarget: GridLayer?

  public var upsideDownTransform: CGAffineTransform {
    .init(scaleX: 1, y: -1)
      .translatedBy(
        x: 0,
        y: -Double(state.outerGrid!.rowsCount) * state.font.cellHeight
      )
  }

  init(store: Store) {
    self.store = store
    super.init(frame: .init())

    wantsLayer = true
    layer!.masksToBounds = true
    layer!.drawsAsynchronously = true
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
      let scale = newWindow.backingScaleFactor
      layer!.contentsScale = scale

      arrangedGridLayers.values.forEach { $0.contentsScale = scale }
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

  public func render() {
    for gridID in updates.destroyedGridIDs {
      let layer = arrangedGridLayer(forGridWithID: gridID)
      layer.isHidden = true
    }

    let updatedLayoutGridIDs =
      if updates.isFontUpdated {
        Set(state.grids.keys)

      } else {
        updates.updatedLayoutGridIDs
      }

    for gridID in updatedLayoutGridIDs {
      guard let grid = state.grids[gridID] else {
        continue
      }

      let gridLayer = arrangedGridLayer(forGridWithID: gridID)
      gridLayer.isHidden = grid.isHidden

      if gridID == Grid.OuterID {
        invalidateIntrinsicContentSize()
      } else if let associatedWindow = grid.associatedWindow {
        switch associatedWindow {
        case .external:
          gridLayer.isHidden = true

        default:
          break
        }
      }
    }

    if !updatedLayoutGridIDs.isEmpty || updates.isGridsHierarchyUpdated {
      let upsideDownTransform = upsideDownTransform

      state.walkingGridFrames { id, frame, zPosition in
        guard let gridLayer = arrangedGridLayers[id] else {
          logger.warning("walkingGridFrames: gridLayer with id \(id) not found")
          return
        }
        guard !gridLayer.isHidden else {
          return
        }
        if updatedLayoutGridIDs.contains(id) {
          gridLayer.frame = frame.applying(upsideDownTransform)
        }
        if updates.isGridsHierarchyUpdated, gridLayer.zPosition != zPosition {
          gridLayer.zPosition = zPosition
        }
      }
    }

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    defer { CATransaction.commit() }

    renderChildren(
      arrangedGridLayers.values
        .lazy
        .filter { !$0.isHidden }
    )
  }

  public func windowFrame(
    forGridID gridID: Grid.ID,
    gridFrame: IntegerRectangle
  )
    -> CGRect?
  {
    arrangedGridLayers[gridID]?.windowFrame(forGridFrame: gridFrame)
  }

  public func arrangedGridLayer(forGridWithID id: Grid.ID) -> GridLayer {
    if let layer = arrangedGridLayers[id] {
      return layer

    } else {
      let layer = GridLayer(
        store: store,
        gridID: id,
        contentsScale: layer!.contentsScale
      )
      renderChildren(layer)
      self.layer!.addSublayer(layer)
      arrangedGridLayers[id] = layer
      return layer
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

  private func point(for event: NSEvent) -> IntegerPoint {
    let upsideDownLocation = convert(event.locationInWindow, from: nil)
      .applying(upsideDownTransform)
    return .init(
      column: Int(upsideDownLocation.x / state.font.cellWidth),
      row: Int(upsideDownLocation.y / state.font.cellHeight)
    )
  }
}
