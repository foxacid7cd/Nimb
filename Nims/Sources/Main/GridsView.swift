// SPDX-License-Identifier: MIT

import AppKit
import Library

public class GridsView: NSView {
  init(store: Store) {
    self.store = store
    super.init(frame: .init())
    autoresizesSubviews = false
    wantsLayer = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public var intrinsicContentSize: NSSize {
    guard let outerGrid = store.state.outerGrid else {
      return .init()
    }
    return outerGrid.size * store.font.cellSize
  }

  override public var isOpaque: Bool {
    true
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

  override public func mouseMoved(with event: NSEvent) {
    guard let superview else {
      return
    }
    let location = superview.convert(event.locationInWindow, from: nil)
    let viewAtLocation = hitTest(location)
    if let gridView = viewAtLocation as? GridView {
      gridView.reportMouseMove(for: event)
    }
  }

  public func render(_ stateUpdates: State.Updates) {
    for gridID in stateUpdates.destroyedGridIDs {
      gridViews.removeValue(forKey: gridID)?.removeFromSuperview()
    }

    let updatedLayoutGridIDs = if stateUpdates.isFontUpdated {
      Set(store.state.grids.keys)

    } else {
      stateUpdates.updatedLayoutGridIDs
    }

    if updatedLayoutGridIDs.contains(Grid.OuterID) {
      invalidateIntrinsicContentSize()
      renderUpsideDownTransform()
    }

    for gridID in updatedLayoutGridIDs {
      let grid = store.state.grids[gridID]!
      let gridView = gridView(forGridWithID: gridID)
      gridView.frame = gridViewFrame(forGridWithID: gridID)
      gridView.isHidden = grid.isHidden
    }

    if stateUpdates.isGridsOrderUpdated {
      sortSubviews(
        { firstView, secondView, _ in
          let firstOrdinal = (firstView as! GridView).zIndex
          let secondOrdinal = (secondView as! GridView).zIndex

          if firstOrdinal == secondOrdinal {
            return .orderedSame

          } else if firstOrdinal < secondOrdinal {
            return .orderedAscending

          } else {
            return .orderedDescending
          }
        },
        context: nil
      )
    }

    for (gridID, gridView) in gridViews {
      gridView.render(
        stateUpdates: stateUpdates,
        gridUpdate: stateUpdates.gridUpdates[gridID]
      )
    }
  }

  public func windowFrame(forGridID gridID: Grid.ID, gridFrame: IntegerRectangle) -> CGRect? {
    gridViews[gridID]?.windowFrame(forGridFrame: gridFrame)
  }

  public func gridView(forGridWithID id: Grid.ID) -> GridView {
    if let gridView = gridViews[id] {
      return gridView

    } else {
      let gridView = GridView(store: store, gridID: id)
      gridView.translatesAutoresizingMaskIntoConstraints = false
      addSubview(gridView)
      gridViews[id] = gridView
      return gridView
    }
  }

  private var store: Store
  private var gridViews = IntKeyedDictionary<GridView>()
  private var upsideDownTransform = CGAffineTransform.identity

  private func gridViewFrame(forGridWithID id: Grid.ID) -> CGRect {
    let grid = store.state.grids[id]!
    let gridViewSize = grid.size * store.font.cellSize
    let gridViewOrigin: CGPoint
    if id == Grid.OuterID {
      gridViewOrigin = .zero
    } else if let associatedWindow = grid.associatedWindow {
      switch associatedWindow {
      case let .plain(window):
        gridViewOrigin = window.origin * store.font.cellSize

      case let .floating(floatingWindow):
        let anchorGridViewFrame = gridViewFrame(forGridWithID: floatingWindow.anchorGridID)

        let anchorOffset: CGPoint = switch floatingWindow.anchor {
        case .northWest:
          .init(x: 0, y: 0)

        case .northEast:
          .init(x: -gridViewSize.width, y: 0)

        case .southWest:
          .init(x: 0, y: -gridViewSize.height)

        case .southEast:
          .init(x: -gridViewSize.width, y: -gridViewSize.height)
        }

        gridViewOrigin = .init(
          x: anchorGridViewFrame.origin.x + floatingWindow.anchorColumn * store.font.cellWidth + anchorOffset.x,
          y: anchorGridViewFrame.origin.y + floatingWindow.anchorRow * store.font.cellHeight + anchorOffset.y
        )

      case .external:
        return .zero
      }
    } else {
      return .zero
    }

    return .init(origin: gridViewOrigin, size: gridViewSize)
      .applying(upsideDownTransform)
  }

  private func renderUpsideDownTransform() {
    upsideDownTransform = .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(store.state.outerGrid!.rowsCount) * store.font.cellHeight)
  }
}
