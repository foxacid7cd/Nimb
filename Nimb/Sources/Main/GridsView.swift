// SPDX-License-Identifier: MIT

import AppKit
import Collections
import CustomDump

public class GridsView: NSView, Rendering {
  override public var intrinsicContentSize: NSSize {
    guard isRendered, let outerGrid = state.outerGrid else {
      return .zero
    }
    return outerGrid.size * state.font.cellSize
  }

  private var store: Store
  private var arrangedGridViews = IntKeyedDictionary<GridView>()
  private var leftMouseInteractionTarget: GridView?
  private var rightMouseInteractionTarget: GridView?
  private var otherMouseInteractionTarget: GridView?

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

    canDrawConcurrently = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render() {
    for gridID in updates.destroyedGridIDs {
      let view = arrangedGridView(forGridWithID: gridID)
      view.isHidden = true
    }

    let updatedLayoutGridIDs =
      if updates.isFontUpdated {
        Set(state.grids.keys)

      } else {
        updates.updatedLayoutGridIDs
      }

    for gridID in updatedLayoutGridIDs {
      guard let grid = state.grids[gridID] else {
        continue
      }

      let gridView = arrangedGridView(forGridWithID: gridID)
      gridView.isHidden = grid.isHidden

      if gridID == Grid.OuterID {
        invalidateIntrinsicContentSize()
      } else if let associatedWindow = grid.associatedWindow {
        switch associatedWindow {
        case .external:
          gridView.isHidden = true

        default:
          break
        }
      }
    }

    if !updatedLayoutGridIDs.isEmpty || updates.isGridsHierarchyUpdated {
      let upsideDownTransform = upsideDownTransform

      var zPositions = [ObjectIdentifier: Double]()

      state.walkingGridFrames { id, frame, zPosition in
        guard let gridView = arrangedGridViews[id] else {
          logger.warning("walkingGridFrames: gridView with id \(id) not found")
          return
        }

        let newFrame = frame.applying(upsideDownTransform)
        if gridView.frame != newFrame {
          gridView.frame = newFrame
        }

        zPositions[ObjectIdentifier(gridView)] = zPosition
      }

      var zPositionsObject = zPositions as NSDictionary
      withUnsafeMutablePointer(to: &zPositionsObject) { pointer in
        sortSubviews(
          subviewSortingFunction(firstView:secondView:context:),
          context: UnsafeMutableRawPointer(pointer)
        )
      }
    }

    renderChildren(arrangedGridViews.values.lazy.map(\.self))
  }

  public func windowFrame(
    forGridID gridID: Grid.ID,
    gridFrame: IntegerRectangle
  )
    -> CGRect?
  {
    arrangedGridViews[gridID]?.windowFrame(forGridFrame: gridFrame)
  }

  public func arrangedGridView(forGridWithID id: Grid.ID) -> GridView {
    if let view = arrangedGridViews[id] {
      return view

    } else {
      let view = GridView(
        frame: .init(x: 0, y: 0, width: 200, height: 200),
        store: store,
        gridID: id
      )
      renderChildren(view)
      view.autoresizingMask = []
      view.translatesAutoresizingMaskIntoConstraints = false
      addSubview(view)
      arrangedGridViews[id] = view
      return view
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

private func subviewSortingFunction(firstView: NSView, secondView: NSView, context: UnsafeMutableRawPointer?) -> ComparisonResult {
  guard
    let zPositionsObject = context?.assumingMemoryBound(to: NSDictionary.self).pointee,
    let zPositions = zPositionsObject as? [ObjectIdentifier: Double],
    let firstZPosition = zPositions[ObjectIdentifier(firstView)],
    let secondZPosition = zPositions[ObjectIdentifier(secondView)],
    firstZPosition != secondZPosition
  else {
    return .orderedSame
  }
  return firstZPosition < secondZPosition ? .orderedAscending : .orderedDescending
}
