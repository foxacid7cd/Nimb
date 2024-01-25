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
          shouldSortSubviews = true
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
          setupConstraints(to: self)
        } else if let gridWindow = gridView.gridWindow {
          switch gridWindow {
          case let .plain(value):
            setupConstraints(
              to: self,
              origin: value.origin * store.font.cellSize
            )

          case let .floating(value):
            if let anchorGridView = gridViews[value.anchorGridID] {
              let origin = CGPoint(x: value.anchorColumn * store.font.cellWidth, y: value.anchorRow * store.font.cellHeight)
              setupConstraints(to: anchorGridView, origin: origin, anchor: value.anchor)
            } else {
              Loggers.problems.error("floating window anchor was set to grid that is not created or destroyed already")
            }

          case .external:
            gridView.isHidden = true
          }
        } else {
          gridView.isHidden = true
        }

        func setupConstraints(to secondView: NSView, origin: CGPoint = .zero, anchor: FloatingWindow.Anchor? = nil) {
          if let existing = gridView.gridConstraints {
            if existing.secondView === secondView, existing.anchor == anchor {
              existing.horizontal.constant = origin.x
              existing.vertical.constant = origin.y
            } else {
              deactivated.append(existing.horizontal)
              deactivated.append(existing.vertical)
              gridView.gridConstraints = nil
            }
          }
          if gridView.gridConstraints == nil {
            let horizontal: NSLayoutConstraint
            let vertical: NSLayoutConstraint

            switch anchor {
            case .northEast:
              horizontal = gridView.trailingAnchor.constraint(
                equalTo: secondView.leadingAnchor,
                constant: origin.x
              )
              vertical = gridView.topAnchor.constraint(
                equalTo: secondView.topAnchor,
                constant: origin.y
              )
            case .southWest:
              horizontal = gridView.leadingAnchor.constraint(
                equalTo: secondView.leadingAnchor,
                constant: origin.x
              )
              vertical = gridView.bottomAnchor.constraint(
                equalTo: secondView.topAnchor,
                constant: origin.y
              )
            case .southEast:
              horizontal = gridView.trailingAnchor.constraint(
                equalTo: secondView.leadingAnchor,
                constant: origin.x
              )
              vertical = gridView.bottomAnchor.constraint(
                equalTo: secondView.topAnchor,
                constant: origin.y
              )
            default:
              horizontal = gridView.leadingAnchor.constraint(
                equalTo: secondView.leadingAnchor,
                constant: origin.x
              )
              vertical = gridView.topAnchor.constraint(
                equalTo: secondView.topAnchor,
                constant: origin.y
              )
            }
            activated.append(horizontal)
            activated.append(vertical)

            gridView.gridConstraints = (horizontal, vertical, secondView, anchor)
          }
        }

        gridView.invalidateIntrinsicContentSize()
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

    if stateUpdates.isCursorUpdated {
      if let previousGridCursor, let cursor = store.state.cursor, previousGridCursor.gridID == cursor.gridID {
        gridViews[cursor.gridID]?.applyGridCursorMove(from: previousGridCursor.position, to: cursor.position)
        self.previousGridCursor = cursor
      } else {
        if let previousGridCursor {
          gridViews[previousGridCursor.gridID]?.applyGridCursorMove(from: previousGridCursor.position, to: nil)
        }
        if let cursor = store.state.cursor, cursor.gridID >= Grid.OuterID {
          gridViews[cursor.gridID]?.applyGridCursorMove(to: cursor.position)
          previousGridCursor = cursor
        } else {
          previousGridCursor = nil
        }
      }
    }
    if 
      stateUpdates.isCursorBlinkingPhaseUpdated,
      let previousGridCursor,
      let gridView = gridViews[previousGridCursor.gridID]
    {
      gridView.cursorBlinkingPhaseUpdated()
    }
  }

  public func windowFrame(forGridID gridID: Grid.ID, gridFrame: IntegerRectangle) -> CGRect? {
    gridViews[gridID]?.windowFrame(forGridFrame: gridFrame)
  }

  private var store: Store
  private var windowZIndexCounter = 0
  private var previousGridCursor: Cursor?

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
