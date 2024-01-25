// SPDX-License-Identifier: MIT

import AppKit
import Library

public class GridsView: NSView {
  init(store: Store, initialOuterGridSize: IntegerSize) {
    self.store = store
    super.init(frame: .init())
    makeGridView(id: Grid.OuterID, size: initialOuterGridSize)
    clipsToBounds = true
    wantsLayer = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public private(set) var gridViews: IntKeyedDictionary<GridView> = [:]

  override public var intrinsicContentSize: NSSize {
    outerGridView.gridSize * store.font.cellSize
  }

  public var upsideDownTransform: CGAffineTransform {
    .init(scaleX: 1, y: -1)
      .translatedBy(x: 0, y: -Double(outerGridView.gridSize.rowsCount) * store.font.cellHeight)
  }

  override public var isOpaque: Bool {
    true
  }

  public var outerGridView: GridView {
    gridViews[Grid.OuterID]!
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

  public func render(_ stateUpdates: State.Updates) async throws {
    var shouldSortSubviews = false

    var activated = [NSLayoutConstraint]()
    var deactivated = [NSLayoutConstraint]()

    for (gridID, gridUpdate) in stateUpdates.gridsUpdates {
      var shouldGridViewApplyUpdate = true
      var isLayoutUpdated = false

      switch gridUpdate {
      case let .resize(size):
        if gridViews[gridID] == nil {
          makeGridView(id: gridID, size: size)
          shouldGridViewApplyUpdate = false
        }
        isLayoutUpdated = true

      case .winFloatPos,
           .winPos:
        isLayoutUpdated = true
        shouldSortSubviews = true

      case .destroy:
        if let gridView = gridViews.removeValue(forKey: gridID) {
          gridView.removeFromSuperview()
        }
        shouldGridViewApplyUpdate = false
      default:
        break
      }

      if shouldGridViewApplyUpdate {
        if let gridView = gridViews[gridID] {
          try await gridView.apply(gridUpdate: gridUpdate)
        } else {
          Loggers.problems.error("grid view was not created yet or destroyed but grid received grid event \(String(customDumping: gridUpdate))")
        }
      }

      if isLayoutUpdated, let gridView = gridViews[gridID] {
        if gridID == Grid.OuterID {
          UserDefaults.standard.outerGridSize = gridView.gridSize
          invalidateIntrinsicContentSize()

          if let (horizontal, vertical) = gridView.floatingWindowConstraints {
            deactivated.append(horizontal)
            deactivated.append(vertical)
            gridView.floatingWindowConstraints = nil
          }

          if let (leading, top) = gridView.windowConstraints {
            deactivated.append(leading)
            deactivated.append(top)
          }

          let leading = gridView.leading(to: self, priority: .init(rawValue: 800))
          let top = gridView.topToSuperview(priority: .init(rawValue: 800))
          activated.append(leading)
          activated.append(top)
          gridView.windowConstraints = (leading, top)

          gridView.isHidden = false
        } else if let gridWindow = gridView.gridWindow {
          switch gridWindow {
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

            gridView.isHidden = false

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

            if let anchorGridView = gridViews[value.anchorGridID] {
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

              gridView.isHidden = false
            } else {
              Loggers.problems.error("floating window anchor was set to grid that is not created or destroyed already")
              gridView.isHidden = true
            }

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
    }

    NSLayoutConstraint.deactivate(deactivated)
    NSLayoutConstraint.activate(activated)

    if shouldSortSubviews {
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

//    if stateUpdates.isGridsOrderUpdated {
//      sortSubviews(
//        { firstView, secondView, _ in
//          let firstOrdinal = (firstView as! GridView).zIndex
//          let secondOrdinal = (secondView as! GridView).zIndex
//
//          if firstOrdinal == secondOrdinal {
//            return .orderedSame
//
//          } else if firstOrdinal < secondOrdinal {
//            return .orderedAscending
//
//          } else {
//            return .orderedDescending
//          }
//        },
//        context: nil
//      )
//    }
  }

  public func windowFrame(forGridID gridID: Grid.ID, gridFrame: IntegerRectangle) -> CGRect? {
    gridViews[gridID]?.windowFrame(forGridFrame: gridFrame)
  }

  private var store: Store
  private var windowZIndexCounter = 0

  @discardableResult
  private func makeGridView(id: Int, size: IntegerSize) -> GridView {
    let new = GridView(store: store, id: id, size: size)
    new.getNextWindowZIndex = { [unowned self] in nextWindowZIndex() }
    new.translatesAutoresizingMaskIntoConstraints = false
    addSubview(new)
    new.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    new.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    gridViews[id] = new
    return new
  }

  private func nextWindowZIndex() -> Int {
    windowZIndexCounter += 1
    return windowZIndexCounter
  }
}
