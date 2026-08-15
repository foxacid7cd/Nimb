// SPDX-License-Identifier: MIT

import AppKit
import Collections
import NimbCore
import NimbState

public class GridsView: NSView, CALayerDelegate, Rendering {
  override public var intrinsicContentSize: NSSize {
    guard isRendered, let outerGrid = state.outerGrid else {
      return .zero
    }
    return outerGrid.size * state.font.cellSize
  }

  public var renderContext: RenderContext! = nil

  private var store: Store
  private var arrangedGridViews = IntKeyedDictionary<GridView>()
  /// The one Metal surface every grid paints into, and its CoreGraphics
  /// counterpart for the debug A/B. Both cover all the grids, so the two paths
  /// still render the same workload.
  private let metalLayer = GridsMetalLayer()
  private let coreGraphicsLayer = GridsCoreGraphicsLayer()
  /// nil until the first render, so the first pass always applies visibility.
  private var renderingMode: Bool? = nil
  /// The bounds the shared layers were last sized to.
  private var laidOutBounds: CGRect? = nil

  public var upsideDownTransform: CGAffineTransform {
    .init(scaleX: 1, y: -1)
      .translatedBy(
        x: 0,
        y: -Double(state.outerGrid!.rowsCount) * state.font.cellHeight,
      )
  }

  init(store: Store) {
    self.store = store
    super.init(frame: .init())

    canDrawConcurrently = true
    wantsLayer = true
    layer!.isOpaque = false

    // Both get this view as their delegate purely for action(for:forKey:),
    // which returns NSNull and so suppresses implicit animations. Without it
    // every frame change animates, and animating a layer makes CoreAnimation
    // build a presentation copy of it through init(layer:). Neither layer draws
    // through its delegate: GridsMetalLayer overrides display() and
    // GridsCoreGraphicsLayer overrides draw(in:), and an override of either
    // replaces the machinery that would consult a delegate.
    metalLayer.delegate = self
    coreGraphicsLayer.delegate = self

    // Inserted below everything else. The grid views are still in the view
    // hierarchy for hit testing, and a layer-backed ancestor gives each of them
    // an empty layer of its own; those sit above these two and paint nothing.
    coreGraphicsLayer.isHidden = true
    layer!.insertSublayer(coreGraphicsLayer, at: 0)
    layer!.insertSublayer(metalLayer, at: 0)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func layout() {
    super.layout()

    guard laidOutBounds != bounds else {
      return
    }
    laidOutBounds = bounds

    metalLayer.frame = bounds
    metalLayer.updateDrawableSize()
    coreGraphicsLayer.frame = bounds

    // Every grid's instances are positioned relative to the shared layer, so a
    // change in its size invalidates all of them.
    for gridView in arrangedGridViews.values {
      gridView.invalidateBuiltScene()
    }
  }

  override public func viewDidChangeBackingProperties() {
    super.viewDidChangeBackingProperties()

    guard let scale = window?.backingScaleFactor else {
      return
    }
    layer!.contentsScale = scale
    metalLayer.contentsScale = scale
    metalLayer.updateDrawableSize()
    coreGraphicsLayer.contentsScale = scale

    for gridView in arrangedGridViews.values {
      gridView.invalidateBuiltScene()
    }
  }

  public nonisolated func action(for layer: CALayer, forKey event: String) -> (any CAAction)? {
    NSNull()
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

      // walkingGridFrames yields back to front, so this is the stacking order.
      var orderedGridViews = [NSView]()

      state.walkingGridFrames { id, frame, _ in
        guard let gridView = arrangedGridViews[id] else {
          logger.warning("walkingGridFrames: gridView with id \(id) not found")
          return
        }

        let newFrame = frame.applying(upsideDownTransform)
        if gridView.frame != newFrame {
          gridView.frame = newFrame
        }

        orderedGridViews.append(gridView)
      }

      // Apply it. subviews[0] is the backmost view in AppKit, which matches
      // the order above. Anything walkingGridFrames did not visit — hidden or
      // external grids — keeps its relative position underneath.
      let ordered = Set(orderedGridViews.map(ObjectIdentifier.init))
      let unvisited = subviews.filter { !ordered.contains(ObjectIdentifier($0)) }
      let newSubviews = unvisited + orderedGridViews
      if subviews != newSubviews {
        subviews = newSubviews
      }
    }

    renderChildren(arrangedGridViews.values.lazy.map(\.self))

    let didChangeLayout = !updatedLayoutGridIDs.isEmpty
      || updates.isGridsHierarchyUpdated
      || !updates.destroyedGridIDs.isEmpty
    submitFrame(didChangeLayout: didChangeLayout)
  }

  public func windowFrame(
    forGridID gridID: Grid.ID,
    gridFrame: IntegerRectangle,
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
        gridID: id,
      )
      renderChildren(view)
      view.autoresizingMask = []
      view.translatesAutoresizingMaskIntoConstraints = false
      addSubview(view)
      arrangedGridViews[id] = view
      return view
    }
  }

  /// Collects what every grid reported and hands it over as one frame.
  ///
  /// Order is walkingGridFrames' order, which is back to front, and that is
  /// also the order the shared layer draws in -- a floating window on top has
  /// to be encoded after whatever it covers.
  private func submitFrame(didChangeLayout: Bool) {
    let isCoreGraphics = state.debug.isCoreGraphicsRenderingEnabled

    // Compared against the mode actually in effect rather than against
    // updates.isDebugUpdated, which is false on the first render: the flag is
    // restored into the initial state rather than toggled into it.
    let didSwitchRenderingMode = renderingMode != isCoreGraphics
    if didSwitchRenderingMode {
      renderingMode = isCoreGraphics
      // Each layer keeps whatever it last drew, so the one being switched away
      // from would otherwise stay on screen.
      metalLayer.isHidden = isCoreGraphics
      coreGraphicsLayer.isHidden = !isCoreGraphics
      for gridView in arrangedGridViews.values {
        gridView.invalidateBuiltScene()
      }
    }

    guard state.outerGrid != nil else {
      return
    }
    let upsideDownTransform = upsideDownTransform

    var entries = [GridsRenderEntry]()
    var didAnyGridRebuild = false
    state.walkingGridFrames { id, frame, _ in
      guard
        let grid = state.grids[id],
        !grid.isHidden,
        let gridView = arrangedGridViews[id],
        let snapshot = gridView.pendingSnapshot
      else {
        return
      }
      // External windows are drawn by whatever is hosting them, not here --
      // the same grids GridsView keeps hidden.
      if case .external = grid.associatedWindow {
        return
      }

      didAnyGridRebuild = didAnyGridRebuild || gridView.needsSceneRebuild
      entries.append(.init(
        id: id,
        snapshot: snapshot,
        frame: frame.applying(upsideDownTransform),
        needsRebuild: gridView.needsSceneRebuild,
      ))
    }

    // A frame with nothing new in it is dropped rather than re-encoded. Both
    // layers keep what they last drew, so the correct pixels stay on screen.
    guard didAnyGridRebuild || didChangeLayout || didSwitchRenderingMode else {
      return
    }

    if isCoreGraphics {
      coreGraphicsLayer.update(content: .init(
        entries: entries,
        updates: updates,
        backgroundColor: state.appearance.defaultBackgroundColor,
        needsFullRedraw: didChangeLayout || didSwitchRenderingMode
          || updates.isFontUpdated || updates.isAppearanceUpdated,
      ))
      coreGraphicsLayer.render()
      return
    }

    GridsSceneBuildQueue.shared.submit(.init(
      entries: entries,
      liveGridIDs: Set(state.grids.keys),
      bounds: bounds,
      scale: max(metalLayer.contentsScale, 1),
      clearColor: state.appearance.defaultBackgroundColor.metalClearColor,
      target: metalLayer,
    ))
  }

  private func point(for event: NSEvent) -> IntegerPoint {
    let upsideDownLocation = convert(event.locationInWindow, from: nil)
      .applying(upsideDownTransform)
    return .init(
      column: Int(upsideDownLocation.x / state.font.cellWidth),
      row: Int(upsideDownLocation.y / state.font.cellHeight),
    )
  }
}
