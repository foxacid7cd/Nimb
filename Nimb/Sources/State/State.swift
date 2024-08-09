// SPDX-License-Identifier: MIT

import CasePaths
import Collections
import CustomDump
import MyMacro
import Overture

@PublicInit
public struct State: Sendable {
  @PublicInit
  public struct Debug: Sendable, Codable {
    public var isUIEventsLoggingEnabled: Bool = false
    public var isMessagePackInspectorEnabled: Bool = false
    public var isStoreActionsLoggingEnabled: Bool = false
  }

  @PublicInit
  public struct Updates: Sendable {
    public var needFlush: Bool = true
    public var isRawOptionsUpdated: Bool = false
    public var isDebugUpdated: Bool = false
    public var isModeUpdated: Bool = false
    public var isTitleUpdated: Bool = false
    public var isFontUpdated: Bool = false
    public var isAppearanceUpdated: Bool = false
    public var updatedObservedHighlightNames: Set<
      Appearance
        .ObservedHighlightName
    > = []
    public var isCursorUpdated: Bool = false
    public var tabline: TablineUpdate = .init()
    public var isCmdlinesUpdated: Bool = false
    public var msgShowsUpdates: [MsgShowsUpdate] = []
    public var updatedLayoutGridIDs: Set<Grid.ID> = []
    public var gridUpdates: IntKeyedDictionary<Grid.UpdateResult> = [:]
    public var destroyedGridIDs: Set<Grid.ID> = []
    public var isPopupmenuUpdated: Bool = false
    public var isPopupmenuSelectionUpdated: Bool = false
    public var isCursorBlinkingPhaseUpdated: Bool = false
    public var isBusyUpdated: Bool = false
    public var isMouseOnUpdated: Bool = false
    public var isNimbNotifiesUpdated: Bool = false

    public var isOuterGridLayoutUpdated: Bool {
      updatedLayoutGridIDs.contains(Grid.OuterID)
    }

    public var isMouseUserInteractionEnabledUpdated: Bool {
      isMouseOnUpdated || isBusyUpdated
    }

    public mutating func formUnion(_ updates: Updates) {
      needFlush = needFlush || updates.needFlush
      isRawOptionsUpdated = isRawOptionsUpdated || updates.isRawOptionsUpdated
      isDebugUpdated = isDebugUpdated || updates.isDebugUpdated
      isModeUpdated = isModeUpdated || updates.isModeUpdated
      isTitleUpdated = isTitleUpdated || updates.isTitleUpdated
      isFontUpdated = isFontUpdated || updates.isFontUpdated
      isAppearanceUpdated = isAppearanceUpdated || updates.isAppearanceUpdated
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
        update(&gridUpdates[gridID]) { accumulator in
          if accumulator == nil {
            accumulator = gridUpdate
          } else {
            accumulator!.formUnion(gridUpdate)
          }
        }
      }
      isPopupmenuUpdated = isPopupmenuUpdated || updates.isPopupmenuUpdated
      isPopupmenuSelectionUpdated = isPopupmenuSelectionUpdated || updates
        .isPopupmenuSelectionUpdated
      isCursorBlinkingPhaseUpdated = isCursorBlinkingPhaseUpdated || updates
        .isCursorBlinkingPhaseUpdated
      isBusyUpdated = isBusyUpdated || updates.isBusyUpdated
      isMouseOnUpdated = isMouseOnUpdated || updates.isMouseOnUpdated
      isNimbNotifiesUpdated = isNimbNotifiesUpdated || updates.isNimbNotifiesUpdated
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
  public var popupmenu: Popupmenu? = nil
  public var cursorBlinkingPhase: Bool = true
  public var isBusy: Bool = false
  public var isMouseOn: Bool = true
  public var nimbNotifies: [NimbNotify] = []
  public var gridZIndexCounter: Double = 0

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

  public func orderedGridIDs() -> [Grid.ID] {
    grids
      .map { $1 }
      .sorted(by: { first, second in
        if first.zIndex != second.zIndex {
          first.zIndex < second.zIndex
        } else {
          first.id < second.id
        }
      })
      .map(\.id)
  }

  public mutating func flushDrawRuns() {
    for gridID in grids.keys {
      grids[gridID]!.flushDrawRuns(font: font, appearance: appearance)
    }
  }

  public mutating func updateGridZIndex(id: Grid.ID) {
    gridZIndexCounter += 1

    update(&grids[id]) { [gridZIndexCounter] grid in
      guard grid != nil else {
        return
      }
      grid!.zIndex =
        if id == Grid.OuterID {
          0
        } else if grid!.associatedWindow != nil {
          if case .floating = grid!.associatedWindow {
            gridZIndexCounter + 10000
          } else {
            gridZIndexCounter
          }
        } else {
          -1
        }
    }
  }

  public mutating func apply(updates: Updates, from state: State) {
    gridZIndexCounter = state.gridZIndexCounter
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
  }
}
