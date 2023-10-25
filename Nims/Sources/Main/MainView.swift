// SPDX-License-Identifier: MIT

import AppKit
import Library

class MainView: NSView {
  init(store: Store) {
    self.store = store
    super.init(frame: .init())

    trackingArea = .init(
      rect: bounds,
      options: [.inVisibleRect, .activeInKeyWindow, .mouseMoved],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(trackingArea!)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render(_ stateUpdates: State.Updates) {
    let updatedLayoutGridIDs = if stateUpdates.isFontUpdated {
      Set(store.state.grids.keys)

    } else {
      stateUpdates.updatedLayoutGridIDs
    }

    if stateUpdates.updatedLayoutGridIDs.contains(Grid.OuterID) || stateUpdates.isFontUpdated {
      invalidateIntrinsicContentSize()
    }

    func gridViewOrCreate(forGridID gridID: Grid.ID) -> GridView {
      if let gridView = gridViews[gridID] {
        gridView.invalidateIntrinsicContentSize()
        return gridView

      } else {
        let gridView = GridView(store: store, gridID: gridID)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gridView)
        gridView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        gridView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        gridViews[gridID] = gridView
        return gridView
      }
    }

    for gridID in updatedLayoutGridIDs {
      if let grid = store.state.grids[gridID] {
        let gridView = gridViewOrCreate(forGridID: gridID)

        if gridID == Grid.OuterID {
          gridView.floatingWindowConstraints?.horizontal.isActive = false
          gridView.floatingWindowConstraints?.vertical.isActive = false
          gridView.floatingWindowConstraints = nil

          if let constraints = gridView.windowConstraints {
            constraints.leading.constant = 0
            constraints.top.constant = 0

          } else {
            let leadingConstraint = gridView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
            leadingConstraint.priority = .defaultHigh
            leadingConstraint.isActive = true

            let topConstraint = gridView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
            topConstraint.priority = .defaultHigh
            topConstraint.isActive = true

            gridView.windowConstraints = (leadingConstraint, topConstraint)
          }

          gridView.isHidden = false

        } else if let associatedWindow = grid.associatedWindow {
          switch associatedWindow {
          case let .plain(value):
            let windowFrame = value.frame * store.font.cellSize

            gridView.floatingWindowConstraints?.horizontal.isActive = false
            gridView.floatingWindowConstraints?.vertical.isActive = false
            gridView.floatingWindowConstraints = nil

            if let constraints = gridView.windowConstraints {
              constraints.leading.constant = windowFrame.minX
              constraints.top.constant = windowFrame.minY

            } else {
              let leadingConstraint = gridView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: windowFrame.minX
              )
              leadingConstraint.priority = .defaultHigh
              leadingConstraint.isActive = true

              let topConstraint = gridView.topAnchor.constraint(equalTo: topAnchor, constant: windowFrame.minY)
              topConstraint.priority = .defaultHigh
              topConstraint.isActive = true

              gridView.windowConstraints = (leadingConstraint, topConstraint)
            }

            gridView.isHidden = grid.isHidden

          case let .floating(value):
            gridView.windowConstraints?.leading.isActive = false
            gridView.windowConstraints?.top.isActive = false
            gridView.windowConstraints = nil

            gridView.floatingWindowConstraints?.horizontal.isActive = false
            gridView.floatingWindowConstraints?.vertical.isActive = false
            gridView.floatingWindowConstraints = nil

            let anchorGridView = gridViewOrCreate(forGridID: value.anchorGridID)

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

            horizontal.isActive = true
            vertical.isActive = true
            gridView.floatingWindowConstraints = (horizontal, vertical)

            gridView.isHidden = grid.isHidden

          case .external:
            gridView.windowConstraints?.leading.isActive = false
            gridView.windowConstraints?.top.isActive = false
            gridView.windowConstraints = nil

            gridView.floatingWindowConstraints?.horizontal.isActive = false
            gridView.floatingWindowConstraints?.vertical.isActive = false
            gridView.floatingWindowConstraints = nil

            gridView.isHidden = true
          }

        } else {
          gridView.windowConstraints?.leading.isActive = false
          gridView.windowConstraints?.top.isActive = false
          gridView.windowConstraints = nil

          gridView.floatingWindowConstraints?.horizontal.isActive = false
          gridView.floatingWindowConstraints?.vertical.isActive = false
          gridView.floatingWindowConstraints = nil

          gridView.isHidden = true
        }
      } else {
        gridViews[gridID]?.isHidden = true
      }
    }

    if !updatedLayoutGridIDs.isEmpty {
      sortSubviews(
        { firstView, secondView, _ in
          let firstOrdinal = (firstView as! GridView).ordinal
          let secondOrdinal = (secondView as! GridView).ordinal

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

    for gridView in gridViews.values {
      gridView.render(stateUpdates: stateUpdates)
    }

    for (gridID, gridUpdate) in stateUpdates.gridUpdates {
      guard let gridView = gridViews[gridID] else {
        continue
      }
      gridView.render(gridUpdate: gridUpdate)
    }
  }

  public func point(forGridID gridID: Grid.ID, gridPoint: IntegerPoint) -> CGPoint? {
    guard let gridView = gridViews[gridID] else {
      return nil
    }
    return gridView.point(for: gridPoint) + gridView.frame.origin
  }

  override public func mouseMoved(with event: NSEvent) {
    let location = convert(event.locationInWindow, from: nil)
    if let gridView = hitTest(location) as? GridView {
      gridView.reportMouseMove(for: event)
    }
  }

  override var intrinsicContentSize: NSSize {
    guard let outerGrid = store.state.outerGrid else {
      return .init()
    }
    return outerGrid.size * store.font.cellSize
  }

  private var store: Store
  private var gridViews = IntKeyedDictionary<GridView>()
  private var trackingArea: NSTrackingArea?
}
