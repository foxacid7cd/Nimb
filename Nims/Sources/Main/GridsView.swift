// SPDX-License-Identifier: MIT

import AppKit
import Library

public class GridsView: NSView, AnchorLayoutingLayer {
  init(store: Store) {
    self.store = store
    super.init(frame: .init())

    wantsLayer = true
    layer!.drawsAsynchronously = true
    layer!.actions = [
      "onOrderIn": NSNull(),
      "onOrderOut": NSNull(),
      "sublayers": NSNull(),
      "contents": NSNull(),
      "bounds": NSNull(),
    ]
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var anchoringLayer: AnchorLayoutingLayer?
  public var anchoredLayers = [ObjectIdentifier: AnchorLayoutingLayer]()
  public var positionInAnchoringLayer = CGPoint()
  public var needsAnchorLayout = false

  override public var intrinsicContentSize: NSSize {
    guard let outerGrid = store.state.outerGrid else {
      return .zero
    }
    return outerGrid.size * store.font.cellSize
  }

  public var upsideDownTransform: CGAffineTransform {
    .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(store.state.outerGrid!.rowsCount) * store.font.cellHeight)
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
      layer!.sublayers?.forEach { $0.contentsScale = scale }
    }
  }

  override public func mouseMoved(with event: NSEvent) {
    //    guard let superview else {
    //      return
    //    }
    //    let location = superview.convert(event.locationInWindow, from: nil)
    //    let viewAtLocation = hitTest(location)
    //    if let gridView = viewAtLocation as? GridView {
    //      gridView.reportMouseMove(for: event)
    //    }
  }

  public func render(_ stateUpdates: State.Updates) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    defer { CATransaction.commit() }

    for gridID in stateUpdates.destroyedGridIDs {
      if let layer = arrangedGridLayers.removeValue(forKey: gridID) {
        layer.removeAnchoring()
        layer.removeFromSuperlayer()
      }
    }

    let updatedLayoutGridIDs = if stateUpdates.isFontUpdated {
      Set(store.state.grids.keys)

    } else {
      stateUpdates.updatedLayoutGridIDs
    }

    for gridID in updatedLayoutGridIDs {
      if gridID == Grid.OuterID {
        invalidateIntrinsicContentSize()
      }

      guard let grid = store.state.grids[gridID] else {
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

          gridLayer.positionInAnchoringLayer = window.origin * store.font.cellSize
        case let .floating(floatingWindow):
          let anchoringLayer = arrangedGridLayer(forGridWithID: floatingWindow.anchorGridID)

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
            x: gridColumn * store.font.cellWidth,
            y: gridRow * store.font.cellHeight
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
      layoutAnchoredLayers(anchoringLayerOrigin: .init())
    }

    for (gridID, layer) in arrangedGridLayers {
      layer.render(
        stateUpdates: stateUpdates,
        gridUpdate: stateUpdates.gridUpdates[gridID]
      )
    }
  }

  public func windowFrame(forGridID gridID: Grid.ID, gridFrame: IntegerRectangle) -> CGRect? {
    arrangedGridLayers[gridID]?.windowFrame(forGridFrame: gridFrame)
  }

  public func arrangedGridLayer(forGridWithID id: Grid.ID) -> GridLayer {
    if let layer = arrangedGridLayers[id] {
      return layer

    } else {
      let layer = GridLayer(store: store, gridID: id)
      layer.contentsScale = self.layer!.contentsScale
      self.layer!.addSublayer(layer)
      arrangedGridLayers[id] = layer
      return layer
    }
  }

  public func layoutAnchoredLayers(anchoringLayerOrigin: CGPoint) {
    let origin = anchoringLayerOrigin + positionInAnchoringLayer

    frame = .init(
      origin: origin,
      size: store.state.outerGrid!.size * store.font.cellSize
    )

    for anchoredLayer in anchoredLayers {
      anchoredLayer.value.layoutAnchoredLayers(anchoringLayerOrigin: origin)
    }

    needsAnchorLayout = false
  }

  private var store: Store
  private var arrangedGridLayers = IntKeyedDictionary<GridLayer>()
}
