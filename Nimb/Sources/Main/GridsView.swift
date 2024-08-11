// SPDX-License-Identifier: MIT

import AppKit

public class GridsView: NSView, AnchorLayoutingLayer, CALayerDelegate, Rendering {
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

  public var anchoringLayer: AnchorLayoutingLayer?
  public var anchoredLayers = [ObjectIdentifier: AnchorLayoutingLayer]()
  public var positionInAnchoringLayer = CGPoint()
  public var needsAnchorLayout = false

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
      if let layer = arrangedGridLayers.removeValue(forKey: gridID) {
        layer.removeAnchoring()
        layer.removeFromSuperlayer()
      }
    }

    let updatedLayoutGridIDs =
      if updates.isFontUpdated {
        Set(state.grids.keys)

      } else {
        updates.updatedLayoutGridIDs
      }

    for gridID in updatedLayoutGridIDs {
      if gridID == Grid.OuterID {
        invalidateIntrinsicContentSize()
      }

      guard let grid = state.grids[gridID] else {
        continue
      }

      let gridLayer = arrangedGridLayer(forGridWithID: gridID)
      gridLayer.isHidden = grid.isHidden
      gridLayer.removeAnchoring()

      if gridID == Grid.OuterID {
        gridLayer.anchoringLayer = self
        anchoredLayers[.init(gridLayer)] = gridLayer
      } else if let associatedWindow = grid.associatedWindow {
        switch associatedWindow {
        case let .plain(window):
          gridLayer.anchoringLayer = self
          anchoredLayers[.init(gridLayer)] = gridLayer

          gridLayer.positionInAnchoringLayer = window.origin * state.font
            .cellSize

        case let .floating(floatingWindow):
          let anchoringLayer = arrangedGridLayer(
            forGridWithID: floatingWindow
              .anchorGridID
          )

          gridLayer.anchoringLayer = anchoringLayer
          anchoringLayer.anchoredLayers[.init(gridLayer)] = gridLayer

          var gridColumn: Double = floatingWindow.anchorColumn
          var gridRow: Double = floatingWindow.anchorRow

          switch floatingWindow.anchor {
          case .northWest:
            break
          case .northEast:
            gridColumn += Double(anchoringLayer.grid.columnsCount)
          case .southWest:
            gridRow -= Double(anchoringLayer.grid.rowsCount)
          case .southEast:
            gridColumn += Double(anchoringLayer.grid.columnsCount)
            gridRow -= Double(anchoringLayer.grid.rowsCount)
          }

          gridLayer.positionInAnchoringLayer = CGPoint(
            x: gridColumn * state.font.cellWidth,
            y: gridRow * state.font.cellHeight
          )

        case .external:
          gridLayer.isHidden = true
        }
      } else {
        gridLayer.isHidden = true
      }

      gridLayer.needsAnchorLayout = true
    }

    if needsAnchorLayout {
      layoutAnchoredLayers(anchoringLayerOrigin: .init(), index: 0)
    }

    for layer in arrangedGridLayers.values {
      renderChildren(layer)
    }
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
      let layer = GridLayer(store: store, gridID: id)
      renderChildren(layer)
      layer.contentsScale = self.layer!.contentsScale
      self.layer!.addSublayer(layer)
      arrangedGridLayers[id] = layer
      return layer
    }
  }

  public func layoutAnchoredLayers(anchoringLayerOrigin: CGPoint, index: Int) {
    invalidateIntrinsicContentSize()

    for anchoredLayer in anchoredLayers {
      anchoredLayer.value.layoutAnchoredLayers(anchoringLayerOrigin: .zero, index: index * 100)
    }

    needsAnchorLayout = false
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
