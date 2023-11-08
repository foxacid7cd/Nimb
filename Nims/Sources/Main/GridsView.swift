// SPDX-License-Identifier: MIT

import AppKit
import Library

public class GridsView: NSView {
  init(store: Store) {
    self.store = store
    super.init(frame: .init())
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
    }

    var activated = [NSLayoutConstraint]()
    var deactivated = [NSLayoutConstraint]()

    for gridID in updatedLayoutGridIDs {
      let grid = store.state.grids[gridID]!
      let gridView = gridView(forGridWithID: gridID)
      gridView.invalidateIntrinsicContentSize()

      if gridID == Grid.OuterID {
        if let (horizontal, vertical) = gridView.floatingWindowConstraints {
          deactivated.append(horizontal)
          deactivated.append(vertical)
          gridView.floatingWindowConstraints = nil
        }

        if let (leading, top) = gridView.windowConstraints {
          deactivated.append(leading)
          deactivated.append(top)
        }

        let leading = gridView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
        leading.priority = .defaultHigh
        activated.append(leading)

        let top = gridView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        top.priority = .defaultHigh
        activated.append(top)

        gridView.windowConstraints = (leading, top)

        gridView.isHidden = false

      } else if let associatedWindow = grid.associatedWindow {
        switch associatedWindow {
        case let .plain(value):
          let origin = value.origin * store.font.cellSize

          if let (horizontal, vertical) = gridView.floatingWindowConstraints {
            deactivated.append(horizontal)
            deactivated.append(vertical)
            gridView.floatingWindowConstraints = nil
          }

          if let (leading, top) = gridView.windowConstraints {
            deactivated.append(leading)
            deactivated.append(top)
          }
          let leading = gridView.leadingAnchor.constraint(
            equalTo: leadingAnchor,
            constant: origin.x
          )
          leading.priority = .defaultHigh
          activated.append(leading)

          let top = gridView.topAnchor.constraint(equalTo: topAnchor, constant: origin.y)
          top.priority = .defaultHigh
          activated.append(top)

          gridView.windowConstraints = (leading, top)

          gridView.isHidden = grid.isHidden

        case let .floating(value):
          if let (leading, top) = gridView.windowConstraints {
            deactivated.append(leading)
            deactivated.append(top)
            gridView.windowConstraints = nil
          }

          if let (horizontal, vertical) = gridView.floatingWindowConstraints {
            deactivated.append(horizontal)
            deactivated.append(vertical)
            gridView.floatingWindowConstraints = nil
          }

          let anchorGridView = self.gridView(forGridWithID: value.anchorGridID)

          let horizontalConstant: Double = value.anchorColumn * store.font.cellWidth
          let verticalConstant: Double = value.anchorRow * store.font.cellHeight

          let horizontal: NSLayoutConstraint
          let vertical: NSLayoutConstraint

          switch value.anchor {
          case .northWest:
            horizontal = gridView.leadingAnchor.constraint(
              equalTo: anchorGridView.leadingAnchor,
              constant: horizontalConstant
            )
            vertical = gridView.topAnchor.constraint(
              equalTo: anchorGridView.topAnchor,
              constant: verticalConstant
            )

          case .northEast:
            horizontal = gridView.trailingAnchor.constraint(
              equalTo: anchorGridView.leadingAnchor,
              constant: horizontalConstant
            )
            vertical = gridView.topAnchor.constraint(
              equalTo: anchorGridView.topAnchor,
              constant: verticalConstant
            )

          case .southWest:
            horizontal = gridView.leadingAnchor.constraint(
              equalTo: anchorGridView.leadingAnchor,
              constant: horizontalConstant
            )
            vertical = gridView.bottomAnchor.constraint(
              equalTo: anchorGridView.topAnchor,
              constant: verticalConstant
            )

          case .southEast:
            horizontal = gridView.trailingAnchor.constraint(
              equalTo: anchorGridView.leadingAnchor,
              constant: horizontalConstant
            )
            vertical = gridView.bottomAnchor.constraint(
              equalTo: anchorGridView.topAnchor,
              constant: verticalConstant
            )
          }

          activated.append(horizontal)
          activated.append(vertical)
          gridView.floatingWindowConstraints = (horizontal, vertical)

          gridView.isHidden = grid.isHidden

        case .external:
          if let (leading, top) = gridView.windowConstraints {
            deactivated.append(leading)
            deactivated.append(top)
            gridView.windowConstraints = nil
          }

          if let (horizontal, vertical) = gridView.floatingWindowConstraints {
            deactivated.append(horizontal)
            deactivated.append(vertical)
            gridView.floatingWindowConstraints = nil
          }

          gridView.isHidden = true
        }

      } else {
        if let (leading, top) = gridView.windowConstraints {
          deactivated.append(leading)
          deactivated.append(top)
          gridView.windowConstraints = nil
        }

        if let (horizontal, vertical) = gridView.floatingWindowConstraints {
          deactivated.append(horizontal)
          deactivated.append(vertical)
          gridView.floatingWindowConstraints = nil
        }

        gridView.isHidden = true
      }
    }

    NSLayoutConstraint.deactivate(deactivated)
    NSLayoutConstraint.activate(activated)
    if !deactivated.isEmpty || !activated.isEmpty {
      layoutSubtreeIfNeeded()
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
      gridView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
      gridView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
      gridViews[id] = gridView
      return gridView
    }
  }

  private var store: Store
  private var gridViews = IntKeyedDictionary<GridView>()
}
