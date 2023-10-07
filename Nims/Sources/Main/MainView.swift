// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim

class MainView: NSView {
  init(store: Store) {
    self.store = store
    super.init(frame: .init())

    render(.init())
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render(_ stateUpdates: State.Updates) {
    guard let outerGridIntegerSize = store.outerGrid?.cells.size else {
      return
    }
    let outerGridSize = outerGridIntegerSize * store.font.cellSize

    let updatedLayoutGridIDs = if stateUpdates.isFontUpdated {
      Set(store.grids.keys)

    } else {
      stateUpdates.updatedLayoutGridIDs
    }

    func gridViewOrCreate(for gridID: Neovim.Grid.ID) -> GridView {
      if let gridView = gridViews[gridID] {
        return gridView

      } else {
        let gridView = GridView(store: store, gridID: gridID)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gridView)

        let widthConstraint = gridView.widthAnchor.constraint(equalToConstant: 0)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true

        let heightConstraint = gridView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true

        gridView.sizeConstraints = (widthConstraint, heightConstraint)

        gridViews[gridID] = gridView
        return gridView
      }
    }

    for gridID in updatedLayoutGridIDs {
      if let grid = store.grids[gridID] {
        let gridView = gridViewOrCreate(for: gridID)

        if gridID == Grid.OuterID {
          gridView.sizeConstraints!.width.constant = outerGridSize.width
          gridView.sizeConstraints!.height.constant = outerGridSize.height

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
            let windowFrame = (value.frame * store.font.cellSize)

            gridView.sizeConstraints!.width.constant = windowFrame.width
            gridView.sizeConstraints!.height.constant = windowFrame.height

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
            let windowSize = grid.cells.size * store.font.cellSize
            gridView.sizeConstraints!.width.constant = windowSize.width
            gridView.sizeConstraints!.height.constant = windowSize.height

            gridView.windowConstraints?.leading.isActive = false
            gridView.windowConstraints?.top.isActive = false
            gridView.windowConstraints = nil

            gridView.floatingWindowConstraints?.horizontal.isActive = false
            gridView.floatingWindowConstraints?.vertical.isActive = false
            gridView.floatingWindowConstraints = nil

            let anchorGridView = gridViewOrCreate(for: value.anchorGridID)

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
            gridView.sizeConstraints!.width.constant = 0
            gridView.sizeConstraints!.height.constant = 0

            gridView.windowConstraints?.leading.isActive = false
            gridView.windowConstraints?.top.isActive = false
            gridView.windowConstraints = nil

            gridView.floatingWindowConstraints?.horizontal.isActive = false
            gridView.floatingWindowConstraints?.vertical.isActive = false
            gridView.floatingWindowConstraints = nil

            gridView.isHidden = true
          }

        } else {
          gridView.sizeConstraints!.width.constant = 0
          gridView.sizeConstraints!.height.constant = 0

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

    if stateUpdates.updatedLayoutGridIDs.contains(Grid.OuterID) || stateUpdates.isFontUpdated {
      invalidateIntrinsicContentSize()
    }

    if stateUpdates.isAppearanceUpdated {
      for gridView in gridViews.values {
        gridView.setNeedsDisplay(gridView.bounds)
      }

    } else {
      for (gridID, updatedRectangles) in stateUpdates.gridUpdatedRectangles {
        guard let gridView = gridViews[gridID] else {
          continue
        }
        gridView.setNeedsDisplay(updatedRectangles: updatedRectangles)
      }

      if stateUpdates.isCursorBlinkingPhaseUpdated, let cursor = store.cursor, let gridView = gridViews[cursor.gridID] {
        gridView.setNeedsDisplay(
          updatedRectangles: [
            .init(
              origin: cursor.position,
              size: .init(columnsCount: 1, rowsCount: 1)
            ),
          ]
        )
      }
    }
  }

  public func point(forGridID gridID: Grid.ID, gridPoint: IntegerPoint) -> CGPoint? {
    guard let gridView = gridViews[gridID] else {
      return nil
    }
    return gridView.point(for: gridPoint) + gridView.frame.origin
  }

  override var intrinsicContentSize: NSSize {
    let outerGridSize = store.outerGrid?.cells.size
    return (outerGridSize ?? .init()) * store.font.cellSize
  }

  private var store: Store
  private var task: Task<Void, Never>?
  private var gridViews = IntKeyedDictionary<GridView>()
}
