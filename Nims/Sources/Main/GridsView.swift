// SPDX-License-Identifier: MIT

import AppKit
import Library

public class GridsView: NSView, AnchorLayoutingLayer {
  init(store: Store) {
    self.store = store
    super.init(frame: .init())

    wantsLayer = true
    layer!.drawsAsynchronously = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var anchoringLayer: AnchorLayoutingLayer?
  public var anchoredLayers = [ObjectIdentifier: AnchorLayoutingLayer]()
  public var positionInAnchoringLayer = CGPoint()

  override public var intrinsicContentSize: NSSize {
    guard let outerGrid = store.state.outerGrid else {
      return .zero
    }
    return outerGrid.size * store.font.cellSize
  }

  public var upsideDownTransform: CGAffineTransform {
    guard let outerGrid = store.state.outerGrid else {
      return .identity
    }
    return .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(outerGrid.rowsCount) * store.font.cellHeight)
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

//  override public func viewWillMove(toWindow newWindow: NSWindow?) {
//    super.viewWillMove(toWindow: window)
//
//    if let newWindow {
//      layer!.contentsScale = newWindow.backingScaleFactor
//
//      for anchoredLayer in anchoredLayers {
//        (anchoredLayer.value as! CALayer).contentsScale = newWindow.backingScaleFactor
//      }
//    }
//  }

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
    for gridID in stateUpdates.destroyedGridIDs {
      if let (layer, _) = arrangedGridLayers.removeValue(forKey: gridID) {
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

      let (gridLayer, _) = arrangedGridLayer(forGridWithID: gridID)
//      gridView.invalidateIntrinsicContentSize()
      gridLayer.isHidden = grid.isHidden
      gridLayer.removeAnchoring()

      if gridID == Grid.OuterID {
        gridLayer.anchoringLayer = self
        anchoredLayers[.init(gridLayer)] = gridLayer
//        if let constraints, constraints.to === self {
//          constraints.horizontal.constant = 0
//          constraints.vertical.constant = 0
//        } else {
//          if let constraints {
//            constraints.horizontal.isActive = false
//            constraints.vertical.isActive = false
//          }
//
//          let leading = gridView.leading(to: self, priority: .defaultHigh)
//          let top = gridView.topToSuperview(priority: .defaultHigh)
//          leading.isActive = true
//          top.isActive = true
//          arrangedGridViews[gridID]!.constraints = .init(to: self, horizontal: leading, vertical: top)
//        }
      } else if let associatedWindow = grid.associatedWindow {
        let (gridLayer, _) = arrangedGridLayers[gridID]!

        switch associatedWindow {
        case let .plain(window):
          gridLayer.anchoringLayer = self
          anchoredLayers[.init(gridLayer)] = gridLayer
          gridLayer.positionInAnchoringLayer = window.origin * store.font.cellSize

//          if let constraints, constraints.to === self, constraints.anchor == nil {
//            constraints.horizontal.constant = origin.x
//            constraints.vertical.constant = origin.y
//          } else {
//            if let constraints {
//              constraints.horizontal.isActive = false
//              constraints.vertical.isActive = false
//            }
//
//            let leading = gridView.leading(to: self, offset: origin.x, priority: .defaultHigh)
//            let top = gridView.topToSuperview(offset: origin.y, priority: .defaultHigh)
//            leading.isActive = true
//            top.isActive = true
//            arrangedGridViews[gridID]!.constraints = .init(to: self, horizontal: leading, vertical: top)
//          }
        case let .floating(floatingWindow):
          let anchoringLayer = arrangedGridLayer(forGridWithID: floatingWindow.anchorGridID).layer

          gridLayer.anchoringLayer = anchoringLayer
          anchoringLayer.anchoredLayers[.init(gridLayer)] = gridLayer

          gridLayer.positionInAnchoringLayer = CGPoint(
            x: floatingWindow.anchorColumn * store.font.cellWidth,
            y: floatingWindow.anchorRow * store.font.cellHeight
          )
//          gridLayer.frame = .init(origin: origin, size: grid.size * store.font.cellSize)
//          let horizontalConstant: Double = floatingWindow.anchorColumn * store.font.cellWidth
//          let verticalConstant: Double = floatingWindow.anchorRow * store.font.cellHeight
//
//          let (anchorGridView, _) = arrangedGridView(forGridWithID: floatingWindow.anchorGridID)
//
//          if let constraints, constraints.to === anchorGridView, constraints.anchor == floatingWindow.anchor {
//            constraints.horizontal.constant = horizontalConstant
//            constraints.vertical.constant = verticalConstant
//          } else {
//            if let constraints {
//              constraints.horizontal.isActive = false
//              constraints.vertical.isActive = false
//            }
//
//            let horizontal: NSLayoutConstraint
//            let vertical: NSLayoutConstraint
//            switch floatingWindow.anchor {
//            case .northWest:
//              horizontal = gridView.leadingAnchor.constraint(
//                equalTo: anchorGridView.leadingAnchor
//              )
//              vertical = gridView.topAnchor.constraint(
//                equalTo: anchorGridView.topAnchor
//              )
//            case .northEast:
//              horizontal = gridView.trailingAnchor.constraint(
//                equalTo: anchorGridView.leadingAnchor
//              )
//              vertical = gridView.topAnchor.constraint(
//                equalTo: anchorGridView.topAnchor
//              )
//            case .southWest:
//              horizontal = gridView.leadingAnchor.constraint(
//                equalTo: anchorGridView.leadingAnchor
//              )
//              vertical = gridView.bottomAnchor.constraint(
//                equalTo: anchorGridView.topAnchor
//              )
//            case .southEast:
//              horizontal = gridView.trailingAnchor.constraint(
//                equalTo: anchorGridView.leadingAnchor
//              )
//              vertical = gridView.bottomAnchor.constraint(
//                equalTo: anchorGridView.topAnchor
//              )
//            }
//            horizontal.constant = horizontalConstant
//            vertical.constant = verticalConstant
//
//            horizontal.isActive = true
//            vertical.isActive = true
//
//            arrangedGridViews[gridID]!.constraints = .init(
//              to: anchorGridView,
//              horizontal: horizontal,
//              vertical: vertical,
//              anchor: floatingWindow.anchor
//            )
//          }
        case .external:
//          if let constraints {
//            constraints.horizontal.isActive = false
//            constraints.vertical.isActive = false
//            arrangedGridViews[gridID]!.constraints = nil
//          }
          gridLayer.isHidden = true
        }
      } else {
//        if let constraints {
//          constraints.horizontal.isActive = false
//          constraints.vertical.isActive = false
//          arrangedGridViews[gridID]!.constraints = nil
//        }
        gridLayer.isHidden = true
      }
    }

    for (gridID, (gridLayer, _)) in arrangedGridLayers {
      gridLayer.render(
        stateUpdates: stateUpdates,
        gridUpdate: stateUpdates.gridUpdates[gridID]
      )
    }

    layoutAnchoredLayers(anchoringLayerOrigin: .init())

//    if stateUpdates.isGridsOrderUpdated || hasAddedGridLayers {
//      for sublayer in layer!.sublayers! {
//        let gridLayer = sublayer as! GridLayer
//        gridLayer.zPosition = gridLayer.grid.zIndex
//      }
//      sortSubviews(
//        { firstView, secondView, _ in
//          let firstOrdinal = (firstView as! GridView).zIndex
//          let secondOrdinal = (secondView as! GridView).zIndex
//
//          return if firstOrdinal == secondOrdinal {
//            .orderedSame
//          } else if firstOrdinal < secondOrdinal {
//            .orderedAscending
//          } else {
//            .orderedDescending
//          }
//        },
//        context: nil
//      )
//    for (_, context) in arrangedGridLayers {
//      let layer = context.layer
//      layer.zPosition = layer.grid.zIndex
//    }
//      hasAddedGridLayers = false
//    }
  }

  public func windowFrame(forGridID gridID: Grid.ID, gridFrame: IntegerRectangle) -> CGRect? {
//    arrangedGridLayers[gridID]?.layer.windowFrame(forGridFrame: gridFrame)
    .init()
  }

  public func arrangedGridLayer(forGridWithID id: Grid.ID) -> (layer: GridLayer, context: ()) {
    if let context = arrangedGridLayers[id] {
      return context

    } else {
      let layer = GridLayer(store: store, gridID: id)
      layer.contentsScale = self.layer!.contentsScale
//      view.translatesAutoresizingMaskIntoConstraints = false
      self.layer!.addSublayer(layer)
//      addSubview(view)
//      view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
//      view.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
      arrangedGridLayers[id] = (layer, ())
      hasAddedGridLayers = true
      return (layer, ())
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
  }

  private var store: Store
  private var arrangedGridLayers = IntKeyedDictionary<(layer: GridLayer, context: ())>()
  private var hasAddedGridLayers = false
}
