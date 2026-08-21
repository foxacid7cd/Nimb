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
    /// Accumulate per-stage render timings and log a summary every 120 frames.
    /// Signposts are always emitted; this only turns on the clock reads and the
    /// aggregation behind them, so a regression is visible without Instruments.
    public var isFrameStatsLoggingEnabled: Bool = false
    /// Drive the reducer on the main actor instead of the cooperative pool.
    ///
    /// Only useful for measurement. The reducer and the render walk normally
    /// run on different threads, so their costs overlap and neither timing
    /// includes waiting for the other; putting them on the same thread makes
    /// the two add up into one number, and makes any contention between them
    /// show up as time rather than hiding in a stall. Read once when the store
    /// is built, so it takes effect on the next launch.
    public var isReducingOnMainThreadEnabled: Bool = false
  }

  @PublicInit
  public struct Updates: Sendable {
    public var needFlush: Bool = false
    public var isRawOptionsUpdated: Bool = false
    public var isDebugUpdated: Bool = false
    public var isModeUpdated: Bool = false
    public var isTitleUpdated: Bool = false
    public var isFontUpdated: Bool = false
    public var isAppearanceUpdated: Bool = false
    /// A highlight definition changed.
    ///
    /// Weaker than isAppearanceUpdated, which forces every row of every grid
    /// to reshape and every view to be reconstructed — far too much for a
    /// colour change, since draw runs hold highlight ids and resolve colours
    /// when they are drawn. Renderers that instead bake colours into geometry
    /// ahead of time need to know, and this is what tells them.
    public var isHighlightsUpdated: Bool = false
    public var updatedObservedHighlightNames: Set<
      Appearance
        .ObservedHighlightName,
    > = []
    public var isCursorUpdated: Bool = false
    public var tabline: TablineUpdate = .init()
    public var isCmdlinesUpdated: Bool = false
    public var msgShowsUpdates: [MsgShowsUpdate] = []
    public var updatedLayoutGridIDs: Set<Grid.ID> = []
    public var gridUpdates: IntKeyedDictionary<Grid.UpdateResult> = [:]
    public var destroyedGridIDs: Set<Grid.ID> = []
    public var isGridsHierarchyUpdated: Bool = false
    public var isPopupmenuUpdated: Bool = false
    public var isPopupmenuSelectionUpdated: Bool = false
    public var isCursorBlinkingPhaseUpdated: Bool = false
    public var isBusyUpdated: Bool = false
    public var isMouseOnUpdated: Bool = false
    public var isNimbNotifiesUpdated: Bool = false
    public var isApplicationActiveUpdated: Bool = false
    public var isErrorExitStatusUpdated: Bool = false

    public var isOuterGridLayoutUpdated: Bool {
      updatedLayoutGridIDs.contains(Grid.OuterID)
    }

    public var isMouseUserInteractionEnabledUpdated: Bool {
      isMouseOnUpdated || isBusyUpdated
    }

    public mutating func formUnion(_ updates: Updates) {
      needFlush = updates.needFlush
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
      isCmdlinesUpdated = isCmdlinesUpdated || updates.isCmdlinesUpdated
      msgShowsUpdates.append(contentsOf: updates.msgShowsUpdates)
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
      isGridsHierarchyUpdated = isGridsHierarchyUpdated || updates.isGridsHierarchyUpdated
      isPopupmenuUpdated = isPopupmenuUpdated || updates.isPopupmenuUpdated
      isPopupmenuSelectionUpdated = isPopupmenuSelectionUpdated || updates
        .isPopupmenuSelectionUpdated
      isCursorBlinkingPhaseUpdated = isCursorBlinkingPhaseUpdated || updates
        .isCursorBlinkingPhaseUpdated
      isBusyUpdated = isBusyUpdated || updates.isBusyUpdated
      isMouseOnUpdated = isMouseOnUpdated || updates.isMouseOnUpdated
      isNimbNotifiesUpdated = isNimbNotifiesUpdated || updates.isNimbNotifiesUpdated
      isApplicationActiveUpdated = isApplicationActiveUpdated || updates.isApplicationActiveUpdated
      isErrorExitStatusUpdated = isErrorExitStatusUpdated || updates.isErrorExitStatusUpdated
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

  public enum MsgShowsUpdate: Sendable {
    case added(count: Int)
    case reload(indexes: Set<Int>)
    case clear
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
  public var cmdlines: Cmdlines = .init()
  public var msgShows: [MsgShow] = []
  public var grids: IntKeyedDictionary<Grid> = [:]
  public var gridsHierarchy: GridsHierarchy = .init()
  public var popupmenu: Popupmenu? = nil
  public var cursorBlinkingPhase: Bool = true
  public var isBusy: Bool = false
  public var isMouseOn: Bool = true
  public var nimbNotifies: [NimbNotify] = []
  public var isApplicationActive: Bool = false
  public var errorExitStatus: Int? = nil

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

  public var hasModalMsgShows: Bool {
    msgShows.contains(where: { MsgShow.Kind.modal.contains($0.kind) })
  }

  public var isMouseUserInteractionEnabled: Bool {
    isMouseOn && !isBusy
  }

  public var shouldNextMouseEventStopinsert: Bool {
    if hasModalMsgShows {
      return false
    }

    if let popupmenu, case .grid = popupmenu.anchor {
      return true
    }

    return false
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
    if updates.isCmdlinesUpdated {
      cmdlines = state.cmdlines
    }
    if !updates.msgShowsUpdates.isEmpty {
      msgShows = state.msgShows
    }
    if !updates.updatedLayoutGridIDs.isEmpty || !updates.gridUpdates.isEmpty || !updates.destroyedGridIDs.isEmpty {
      grids = state.grids
    }
    if updates.isGridsHierarchyUpdated {
      gridsHierarchy = state.gridsHierarchy
    }
    if updates.isPopupmenuUpdated || updates.isPopupmenuSelectionUpdated {
      popupmenu = state.popupmenu
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
  }

  public func walkingGridFrames(_ body: (_ id: Grid.ID, _ frame: CGRect, _ zPosition: Double) throws -> Void) rethrows {
    var queue: Deque<(id: Grid.ID, depth: Int, indexInParent: Int)> = [(id: Grid.OuterID, depth: 0, indexInParent: 0)]
    var layouts = OrderedDictionary<Grid.ID, (size: IntegerSize, positionInParent: CGPoint, depth: Int, indexInParent: Int, floatingZIndex: Int?)>()
    while let (id, depth, indexInParent) = queue.popFirst() {
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
            depth: depth,
            indexInParent: indexInParent,
            floatingZIndex: nil,
          ),
          forKey: id,
          insertingAt: 0,
        )

      } else if let associatedWindow = grid.associatedWindow {
        switch associatedWindow {
        case let .plain(window):
          var position: Int?
          for (index, layout) in layouts.values.enumerated() {
            if depth < layout.depth {
              position = index
              break
            } else if depth == layout.depth {
              if layout.floatingZIndex != nil {
                position = index
                break
              }
              if indexInParent < layout.indexInParent {
                position = index
                break
              }
            }
          }

          layouts.updateValue(
            (
              size: window.size,
              positionInParent: window.origin * font.cellSize,
              depth: depth,
              indexInParent: indexInParent,
              floatingZIndex: nil,
            ),
            forKey: id,
            insertingAt: position ?? layouts.count,
          )

        case let .floating(floatingWindow):
          // Positioned from screen_row/screen_col rather than worked out from
          // the anchor. Neovim has already resolved the anchor corner and
          // clamped the result to the screen, which the manual route would
          // make our job.
          let gridSize = grid.size
          let gridColumn = Double(floatingWindow.screenColumn)
          let gridRow = Double(floatingWindow.screenRow)

          var position: Int?
          for (index, layout) in layouts.values.enumerated() {
            if depth < layout.depth {
              position = index
              break
            } else if depth == layout.depth {
              // compindex is the order nvim itself renders these in.
              if let layoutFloatingZIndex = layout.floatingZIndex {
                if floatingWindow.compositingIndex < layoutFloatingZIndex {
                  position = index
                  break
                } else if floatingWindow.compositingIndex == layoutFloatingZIndex {
                  if indexInParent < layout.indexInParent {
                    position = index
                    break
                  }
                }
              }
            }
          }

          layouts.updateValue(
            (
              size: gridSize,
              // Already screen absolute, so unlike the plain-window case
              // there is no parent offset to add.
              positionInParent: .init(
                x: gridColumn * font.cellWidth,
                y: gridRow * font.cellHeight,
              ),
              depth: depth,
              indexInParent: indexInParent,
              floatingZIndex: floatingWindow.compositingIndex,
            ),
            forKey: id,
            insertingAt: position ?? layouts.count,
          )

        case .external:
          break
        }
      }

      let nextDepth = depth + 1
      for (index, id) in gridsHierarchyNode.children.enumerated() {
        queue.append((id: id, depth: nextDepth, indexInParent: index))
      }
    }

    for (index, keyValues) in layouts.enumerated() {
      let (id, layout) = keyValues

      let frame = CGRect(
        origin: layout.positionInParent,
        size: layout.size * font.cellSize,
      )
      try body(id, frame, Double(index))
    }
  }
}
