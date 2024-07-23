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

  public struct ArrangedGridViewConstraints {
    weak var to: NSView?
    var horizontal: NSLayoutConstraint
    var vertical: NSLayoutConstraint
    var anchor: FloatingWindow.Anchor?
  }

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
      if let context = arrangedGridViews.removeValue(forKey: gridID) {
        context.view.removeFromSuperview()
      } else {
        logger.warning("were asked to destroy unexisting grid view")
      }
    }

    let updatedLayoutGridIDs = if stateUpdates.isFontUpdated {
      Set(store.state.grids.keys)

    } else {
      stateUpdates.updatedLayoutGridIDs
    }

    var activated = [NSLayoutConstraint]()
    var deactivated = [NSLayoutConstraint]()

    for gridID in updatedLayoutGridIDs {
      if gridID == Grid.OuterID {
        invalidateIntrinsicContentSize()
      }

      guard let grid = store.state.grids[gridID] else {
        continue
      }

      let (gridView, constraints) = arrangedGridView(forGridWithID: gridID)
      gridView.invalidateIntrinsicContentSize()
      gridView.isHidden = grid.isHidden

      if gridID == Grid.OuterID {
        if let constraints, constraints.to === self {
          constraints.horizontal.constant = 0
          constraints.vertical.constant = 0
        } else {
          if let constraints {
            deactivated.append(constraints.horizontal)
            deactivated.append(constraints.vertical)
          }

          let leading = gridView.leading(to: self, priority: .defaultHigh)
          let top = gridView.topToSuperview(priority: .defaultHigh)
          activated.append(leading)
          activated.append(top)
          arrangedGridViews[gridID]!.constraints = .init(to: self, horizontal: leading, vertical: top)
        }
      } else if let associatedWindow = grid.associatedWindow {
        switch associatedWindow {
        case let .plain(window):
          let origin = window.origin * store.font.cellSize

          if let constraints, constraints.to === self, constraints.anchor == nil {
            constraints.horizontal.constant = origin.x
            constraints.vertical.constant = origin.y
          } else {
            if let constraints {
              deactivated.append(constraints.horizontal)
              deactivated.append(constraints.vertical)
            }

            let leading = gridView.leading(to: self, offset: origin.x, priority: .defaultHigh)
            let top = gridView.topToSuperview(offset: origin.y, priority: .defaultHigh)
            activated.append(leading)
            activated.append(top)
            arrangedGridViews[gridID]!.constraints = .init(to: self, horizontal: leading, vertical: top)
          }
        case let .floating(floatingWindow):
          let horizontalConstant: Double = floatingWindow.anchorColumn * store.font.cellWidth
          let verticalConstant: Double = floatingWindow.anchorRow * store.font.cellHeight

          let (anchorGridView, _) = arrangedGridView(forGridWithID: floatingWindow.anchorGridID)

          if let constraints, constraints.to === anchorGridView, constraints.anchor == floatingWindow.anchor {
            constraints.horizontal.constant = horizontalConstant
            constraints.vertical.constant = verticalConstant
          } else {
            if let constraints {
              deactivated.append(constraints.horizontal)
              deactivated.append(constraints.vertical)
            }

            let horizontal: NSLayoutConstraint
            let vertical: NSLayoutConstraint
            switch floatingWindow.anchor {
            case .northWest:
              horizontal = gridView.leadingAnchor.constraint(
                equalTo: anchorGridView.leadingAnchor
              )
              vertical = gridView.topAnchor.constraint(
                equalTo: anchorGridView.topAnchor
              )
            case .northEast:
              horizontal = gridView.trailingAnchor.constraint(
                equalTo: anchorGridView.leadingAnchor
              )
              vertical = gridView.topAnchor.constraint(
                equalTo: anchorGridView.topAnchor
              )
            case .southWest:
              horizontal = gridView.leadingAnchor.constraint(
                equalTo: anchorGridView.leadingAnchor
              )
              vertical = gridView.bottomAnchor.constraint(
                equalTo: anchorGridView.topAnchor
              )
            case .southEast:
              horizontal = gridView.trailingAnchor.constraint(
                equalTo: anchorGridView.leadingAnchor
              )
              vertical = gridView.bottomAnchor.constraint(
                equalTo: anchorGridView.topAnchor
              )
            }
            horizontal.constant = horizontalConstant
            vertical.constant = verticalConstant

            activated.append(horizontal)
            activated.append(vertical)

            arrangedGridViews[gridID]!.constraints = .init(
              to: anchorGridView,
              horizontal: horizontal,
              vertical: vertical,
              anchor: floatingWindow.anchor
            )
          }
        case .external:
          if let constraints {
            deactivated.append(constraints.horizontal)
            deactivated.append(constraints.vertical)
            arrangedGridViews[gridID]!.constraints = nil
          }
          gridView.isHidden = true
        }
      } else {
        if let constraints {
          deactivated.append(constraints.horizontal)
          deactivated.append(constraints.vertical)
          arrangedGridViews[gridID]!.constraints = nil
        }
        gridView.isHidden = true
      }
    }

    NSLayoutConstraint.deactivate(deactivated)
    NSLayoutConstraint.activate(activated)

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    for (gridID, (gridView, _)) in arrangedGridViews {
      gridView.render(
        stateUpdates: stateUpdates,
        gridUpdate: stateUpdates.gridUpdates[gridID]
      )
    }
    CATransaction.commit()

    if stateUpdates.isGridsOrderUpdated || hasAddedGridViews {
      sortSubviews(
        { firstView, secondView, _ in
          let firstOrdinal = (firstView as! GridView).zIndex
          let secondOrdinal = (secondView as! GridView).zIndex

          return if firstOrdinal == secondOrdinal {
            .orderedSame
          } else if firstOrdinal < secondOrdinal {
            .orderedAscending
          } else {
            .orderedDescending
          }
        },
        context: nil
      )
      hasAddedGridViews = false
    }
  }

  public func windowFrame(forGridID gridID: Grid.ID, gridFrame: IntegerRectangle) -> CGRect? {
    arrangedGridViews[gridID]?.view.windowFrame(forGridFrame: gridFrame)
  }

  public func arrangedGridView(forGridWithID id: Grid.ID) -> (GridView, ArrangedGridViewConstraints?) {
    if let context = arrangedGridViews[id] {
      return context

    } else {
      let view = GridView(store: store, gridID: id)
      view.translatesAutoresizingMaskIntoConstraints = false
      addSubview(view)
      view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
      view.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
      arrangedGridViews[id] = (view, nil)
      hasAddedGridViews = true
      return (view, nil)
    }
  }

  private var store: Store
  private var arrangedGridViews = IntKeyedDictionary<(view: GridView, constraints: ArrangedGridViewConstraints?)>()
  private var hasAddedGridViews = false
}
