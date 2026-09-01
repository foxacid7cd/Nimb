// SPDX-License-Identifier: MIT

import Collections
import Foundation
import NimbCore
import NimbNeovim
import OrderedCollections

@PublicInit
public struct State: Sendable {
  @PublicInit
  public struct Debug: Sendable, Codable {
    public var isUIEventsLoggingEnabled: Bool = false
    public var isMessagePackInspectorEnabled: Bool = false
    public var isStoreActionsLoggingEnabled: Bool = false
    /// Draw with CoreGraphics/CoreText instead of Metal, so the two can be
    /// compared on the same workload.
    public var isCoreGraphicsRenderingEnabled: Bool = false
    /// Accumulate per-stage render timings and log a summary every 120 frames,
    /// so a regression is visible without Instruments.
    public var isFrameStatsLoggingEnabled: Bool = false
    /// Drive the reducer on the main actor instead of the cooperative pool, so
    /// its cost and the render walk's add up. Read once, at store construction.
    public var isReducingOnMainThreadEnabled: Bool = false

    /// Decoded field by field, treating anything absent as its default: the
    /// synthesised decoding throws on a missing key, and the caller swallows it.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      func flag(_ key: CodingKeys) throws -> Bool {
        try container.decodeIfPresent(Bool.self, forKey: key) ?? false
      }
      isUIEventsLoggingEnabled = try flag(.isUIEventsLoggingEnabled)
      isMessagePackInspectorEnabled = try flag(.isMessagePackInspectorEnabled)
      isStoreActionsLoggingEnabled = try flag(.isStoreActionsLoggingEnabled)
      isCoreGraphicsRenderingEnabled = try flag(.isCoreGraphicsRenderingEnabled)
      isFrameStatsLoggingEnabled = try flag(.isFrameStatsLoggingEnabled)
      isReducingOnMainThreadEnabled = try flag(.isReducingOnMainThreadEnabled)
    }
  }

  @PublicInit
  public struct Updates: Sendable {
    public var needFlush: Bool = false

    /// Set by every redraw batch, whether or not it ended in flush. Read with
    /// `needFlush`, it says whether the frame that batch belongs to is complete.
    public var isFromRedrawBatch: Bool = false
    public var isRawOptionsUpdated: Bool = false
    public var isDebugUpdated: Bool = false
    public var isModeUpdated: Bool = false
    public var isTitleUpdated: Bool = false
    public var isFontUpdated: Bool = false
    public var isAppearanceUpdated: Bool = false
    /// A highlight definition changed. Weaker than isAppearanceUpdated, and
    /// meant for renderers that bake colours into geometry ahead of time.
    public var isHighlightsUpdated: Bool = false
    public var updatedObservedHighlightNames: Set<
      Appearance
        .ObservedHighlightName,
    > = []
    public var isCursorUpdated: Bool = false
    public var tabline: TablineUpdate = .init()
    public var updatedLayoutGridIDs: Set<Grid.ID> = []
    public var updatedViewportGridIDs: Set<Grid.ID> = []
    public var gridUpdates: IntKeyedDictionary<Grid.UpdateResult> = [:]
    public var destroyedGridIDs: Set<Grid.ID> = []
    public var isGridsHierarchyUpdated: Bool = false
    public var isCursorBlinkingPhaseUpdated: Bool = false
    public var isBusyUpdated: Bool = false
    public var isMouseOnUpdated: Bool = false
    public var isNimbNotifiesUpdated: Bool = false
    public var isApplicationActiveUpdated: Bool = false
    public var isWindowKeyUpdated: Bool = false
    public var isErrorExitStatusUpdated: Bool = false
    public var isPendingReattachUpdated: Bool = false
    public var isBellRung: Bool = false
    public var isVisualBellRung: Bool = false

    public var isOuterGridLayoutUpdated: Bool {
      updatedLayoutGridIDs.contains(Grid.OuterID)
    }

    public var isMouseUserInteractionEnabledUpdated: Bool {
      isMouseOnUpdated || isBusyUpdated
    }

    public mutating func formUnion(_ updates: Updates) {
      needFlush = updates.needFlush
      isFromRedrawBatch = updates.isFromRedrawBatch
      isRawOptionsUpdated = isRawOptionsUpdated || updates.isRawOptionsUpdated
      isDebugUpdated = isDebugUpdated || updates.isDebugUpdated
      isModeUpdated = isModeUpdated || updates.isModeUpdated
      isTitleUpdated = isTitleUpdated || updates.isTitleUpdated
      isFontUpdated = isFontUpdated || updates.isFontUpdated
      isAppearanceUpdated = isAppearanceUpdated || updates.isAppearanceUpdated
      isHighlightsUpdated = isHighlightsUpdated || updates.isHighlightsUpdated
      updatedObservedHighlightNames
        .formUnion(updates.updatedObservedHighlightNames)
      isCursorUpdated = isCursorUpdated || updates.isCursorUpdated
      tabline.formUnion(updates.tabline)
      for gridID in updates.destroyedGridIDs {
        updatedLayoutGridIDs.remove(gridID)
        gridUpdates.removeValue(forKey: gridID)
        destroyedGridIDs.insert(gridID)
      }
      for gridID in updates.updatedLayoutGridIDs {
        updatedLayoutGridIDs.insert(gridID)
      }
      for (gridID, gridUpdate) in updates.gridUpdates {
        if var accumulator = gridUpdates[gridID] {
          accumulator.formUnion(gridUpdate)
          gridUpdates[gridID] = accumulator
        } else {
          gridUpdates[gridID] = gridUpdate
        }
      }
      updatedViewportGridIDs.formUnion(updates.updatedViewportGridIDs)
      isGridsHierarchyUpdated = isGridsHierarchyUpdated || updates.isGridsHierarchyUpdated
      isCursorBlinkingPhaseUpdated = isCursorBlinkingPhaseUpdated || updates
        .isCursorBlinkingPhaseUpdated
      isBusyUpdated = isBusyUpdated || updates.isBusyUpdated
      isMouseOnUpdated = isMouseOnUpdated || updates.isMouseOnUpdated
      isNimbNotifiesUpdated = isNimbNotifiesUpdated || updates.isNimbNotifiesUpdated
      isApplicationActiveUpdated = isApplicationActiveUpdated || updates.isApplicationActiveUpdated
      isWindowKeyUpdated = isWindowKeyUpdated || updates.isWindowKeyUpdated
      isErrorExitStatusUpdated = isErrorExitStatusUpdated || updates.isErrorExitStatusUpdated
      isPendingReattachUpdated = isPendingReattachUpdated || updates
        .isPendingReattachUpdated
      // Ored, not counted: two bells inside one frame are still one bell.
      isBellRung = isBellRung || updates.isBellRung
      isVisualBellRung = isVisualBellRung || updates.isVisualBellRung
    }
  }

  @PublicInit
  public struct TablineUpdate: Sendable {
    public var isTabpagesUpdated: Bool = false
    public var isTabpagesContentUpdated: Bool = false
    public var isBuffersUpdated: Bool = false
    public var isSelectedTabpageUpdated: Bool = false
    public var isSelectedBufferUpdated: Bool = false

    public var hasUpdates: Bool {
      isTabpagesUpdated || isTabpagesContentUpdated || isBuffersUpdated || isSelectedTabpageUpdated || isSelectedBufferUpdated
    }

    public mutating func formUnion(_ update: TablineUpdate) {
      isTabpagesUpdated = isTabpagesUpdated || update.isTabpagesUpdated
      isTabpagesContentUpdated = isTabpagesContentUpdated || update
        .isTabpagesContentUpdated
      isBuffersUpdated = isBuffersUpdated || update.isBuffersUpdated
      isSelectedTabpageUpdated = isSelectedTabpageUpdated || update
        .isSelectedTabpageUpdated
      isSelectedBufferUpdated = isSelectedBufferUpdated || update
        .isSelectedBufferUpdated
    }
  }

  public var debug: Debug = .init()
  public var rawOptions: OrderedDictionary<String, Value> = [:]
  public var title: String? = nil
  public var font: Font
  public var appearance: Appearance = .init()
  public var modeInfo: ModeInfo? = nil
  public var mode: Mode? = nil
  public var cursor: Cursor? = nil
  public var tabline: Tabline? = nil
  public var grids: IntKeyedDictionary<Grid> = [:]
  public var viewports: IntKeyedDictionary<Viewport> = [:]
  public var viewportMargins: IntKeyedDictionary<ViewportMargins> = [:]
  public var gridsHierarchy: GridsHierarchy = .init()
  public var cursorBlinkingPhase: Bool = true
  public var isBusy: Bool = false
  public var isMouseOn: Bool = true
  public var nimbNotifies: [NimbNotify] = []
  public var isApplicationActive: Bool = false
  /// The grid window holding focus, which is not the same as the application
  /// being active: a settings window takes keys away from the grid.
  public var isWindowKey: Bool = false
  public var errorExitStatus: Int? = nil

  /// Cleared once the app has acted on it.
  public var pendingReattachAddress: String? = nil

  public var outerGrid: Grid? {
    get {
      grids[Grid.OuterID]
    }
    set {
      grids[Grid.OuterID] = newValue
    }
  }

  public var currentCursorStyle: CursorStyle? {
    guard
      let modeInfo, let mode,
      mode.cursorStyleIndex < modeInfo.cursorStyles.count
    else {
      return nil
    }

    return modeInfo.cursorStyles[mode.cursorStyleIndex]
  }

  public var isMouseUserInteractionEnabled: Bool {
    isMouseOn && !isBusy
  }

  public var shouldNextMouseEventStopinsert: Bool {
    false
  }

  public mutating func flushDrawRuns() {
    for gridID in grids.keys {
      grids[gridID]!.flushDrawRuns(font: font, appearance: appearance)
    }
  }

  public mutating func apply(updates: Updates, from state: State) {
    if updates.isRawOptionsUpdated {
      rawOptions = state.rawOptions
    }
    if updates.isDebugUpdated {
      debug = state.debug
    }
    if updates.isModeUpdated {
      mode = state.mode
    }
    if updates.isTitleUpdated {
      title = state.title
    }
    if updates.isFontUpdated {
      font = state.font
    }
    if updates.isAppearanceUpdated || !updates.updatedObservedHighlightNames.isEmpty {
      appearance = state.appearance
    }
    if updates.isCursorUpdated {
      cursor = state.cursor
    }
    if updates.tabline.hasUpdates {
      tabline = state.tabline
    }
    if !updates.updatedLayoutGridIDs.isEmpty || !updates.gridUpdates.isEmpty || !updates.destroyedGridIDs.isEmpty {
      grids = state.grids
    }
    if !updates.updatedViewportGridIDs.isEmpty {
      viewports = state.viewports
      viewportMargins = state.viewportMargins
    }
    if updates.isGridsHierarchyUpdated {
      gridsHierarchy = state.gridsHierarchy
    }
    if updates.isCursorBlinkingPhaseUpdated {
      cursorBlinkingPhase = state.cursorBlinkingPhase
    }
    if updates.isBusyUpdated {
      isBusy = state.isBusy
    }
    if updates.isMouseOnUpdated {
      isMouseOn = state.isMouseOn
    }
    if updates.isNimbNotifiesUpdated {
      nimbNotifies = state.nimbNotifies
    }
    if updates.isApplicationActiveUpdated {
      isApplicationActive = state.isApplicationActive
    }
    if updates.isWindowKeyUpdated {
      isWindowKey = state.isWindowKey
    }
  }

  public func walkingGridFrames(_ body: (_ id: Grid.ID, _ frame: CGRect, _ zPosition: Double) throws -> Void) rethrows {
    var queue: Deque<Grid.ID> = [Grid.OuterID]
    var layouts = OrderedDictionary<Grid.ID, (size: IntegerSize, positionInParent: CGPoint, compositingIndex: Int?)>()
    while let id = queue.popFirst() {
      guard let grid = grids[id], let gridsHierarchyNode = gridsHierarchy.allNodes[id] else {
        continue
      }

      if layouts[id] != nil {
        logger.fault("walkingGridFrames: internal inconsistency, grid with id \(id) already layouted")
        continue
      }

      if id == Grid.OuterID {
        layouts.updateValue(
          (
            size: grid.size,
            positionInParent: .init(),
            compositingIndex: nil,
          ),
          forKey: id,
          insertingAt: 0,
        )

      } else if let associatedWindow = grid.associatedWindow {
        switch associatedWindow {
        case let .plain(window):
          layouts.updateValue(
            (
              size: window.size,
              positionInParent: window.origin * font.cellSize,
              compositingIndex: nil,
            ),
            forKey: id,
            insertingAt: layouts.count,
          )

        case let .floating(floatingWindow):
          // Positioned from screen_row/screen_col: Neovim has already resolved
          // the anchor corner and clamped the result to the screen.
          let gridSize = grid.size
          let gridColumn = Double(floatingWindow.screenColumn)
          let gridRow = Double(floatingWindow.screenRow)

          layouts.updateValue(
            (
              size: gridSize,
              // Already screen absolute, so unlike the plain-window case
              // there is no parent offset to add.
              positionInParent: .init(
                x: gridColumn * font.cellWidth,
                y: gridRow * font.cellHeight,
              ),
              compositingIndex: floatingWindow.compositingIndex,
            ),
            forKey: id,
            insertingAt: layouts.count,
          )

        case .external:
          break
        }
      }

      for id in gridsHierarchyNode.children {
        queue.append(id)
      }
    }

    let screenSize = (grids[Grid.OuterID]?.size ?? .init()) * font.cellSize

    let orderedLayouts = layouts.enumerated().sorted { lhs, rhs in
      switch (lhs.element.value.compositingIndex, rhs.element.value.compositingIndex) {
      case (nil, .some):
        true
      case (.some, nil):
        false
      case let (.some(lhsIndex), .some(rhsIndex)):
        lhsIndex == rhsIndex ? lhs.offset < rhs.offset : lhsIndex < rhsIndex
      case (nil, nil):
        lhs.offset < rhs.offset
      }
    }

    for (index, keyValues) in orderedLayouts.enumerated() {
      let (id, layout) = keyValues.element

      // Clipped to the screen the way Neovim's own compositor clips: the
      // message grid is allocated at full screen height and then positioned
      // near the bottom, so its unused rows hang below the last screen row.
      let origin = layout.positionInParent
      let size = layout.size * font.cellSize
      let frame = CGRect(
        origin: origin,
        size: .init(
          width: max(0, min(size.width, screenSize.width - origin.x)),
          height: max(0, min(size.height, screenSize.height - origin.y)),
        ),
      )
      try body(id, frame, Double(index))
    }
  }
}
