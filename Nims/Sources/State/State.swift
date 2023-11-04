// SPDX-License-Identifier: MIT

import CasePaths
import Collections
import CustomDump
import Library
import MessagePack
import Overture

@PublicInit
public struct State: Sendable {
  @PublicInit
  public struct Debug: Sendable {
    public var isUIEventsLoggingEnabled: Bool = false
  }

  @PublicInit
  public struct Updates: Sendable {
    public var isDebugUpdated: Bool = false
    public var isModeUpdated: Bool = false
    public var isTitleUpdated: Bool = false
    public var isFontUpdated: Bool = false
    public var isAppearanceUpdated: Bool = false
    public var isCursorUpdated: Bool = false
    public var tabline: TablineUpdate = .init()
    public var isCmdlinesUpdated: Bool = false
    public var isMsgShowsUpdated: Bool = false
    public var updatedLayoutGridIDs: Set<Grid.ID> = []
    public var gridUpdates: IntKeyedDictionary<Grid.UpdateResult> = [:]
    public var destroyedGridIDs: Set<Grid.ID> = []
    public var isPopupmenuUpdated: Bool = false
    public var isPopupmenuSelectionUpdated: Bool = false
    public var isCursorBlinkingPhaseUpdated: Bool = false
    public var isBusyUpdated: Bool = false
    public var isMsgShowsDismissedUpdated: Bool = false

    public var isOuterGridLayoutUpdated: Bool {
      updatedLayoutGridIDs.contains(Grid.OuterID)
    }
  }

  @PublicInit
  public struct TablineUpdate: Sendable {
    public var isTabpagesUpdated: Bool = false
    public var isTabpagesContentUpdated: Bool = false
    public var isBuffersUpdated: Bool = false
    public var isSelectedTabpageUpdated: Bool = false
    public var isSelectedBufferUpdated: Bool = false
  }

  public var debug: Debug = .init()
  public var drawRunCache: DrawRunCache = .init(maximumCount: 100)
  public var rawOptions: OrderedDictionary<String, Value> = [:]
  public var title: String? = nil
  public var font: NimsFont = .init()
  public var appearance: Appearance = .init()
  public var modeInfo: ModeInfo? = nil
  public var mode: Mode? = nil
  public var cursor: Cursor? = nil
  public var tabline: Tabline? = nil
  public var cmdlines: Cmdlines = .init()
  public var msgShows: [MsgShow] = []
  public var grids: IntKeyedDictionary<Grid> = [:]
  public var windowZIndexCounter: Int = 0
  public var popupmenu: Popupmenu? = nil
  public var cursorBlinkingPhase: Bool = true
  public var isBusy: Bool = false
  public var isMsgShowsDismissed: Bool = false

  public var outerGrid: Grid? {
    get {
      grids[Grid.OuterID]
    }
    set {
      grids[Grid.OuterID] = newValue
    }
  }

  public var currentCursorStyle: CursorStyle? {
    guard let modeInfo, let mode, mode.cursorStyleIndex < modeInfo.cursorStyles.count else {
      return nil
    }

    return modeInfo.cursorStyles[mode.cursorStyleIndex]
  }

  public var hasModalMsgShows: Bool {
    msgShows.contains {
      switch $0.kind {
      case .empty:
        false

      case .confirm:
        true

      case .confirmSub:
        true

      case .emsg:
        false

      case .echo:
        false

      case .echomsg:
        false

      case .echoerr:
        false

      case .luaError:
        false

      case .rpcError:
        false

      case .returnPrompt:
        true

      case .quickfix:
        true

      case .searchCount:
        false

      case .wmsg:
        true
      }
    }
  }

  public mutating func nextWindowZIndex() -> Int {
    windowZIndexCounter += 1
    return windowZIndexCounter
  }

  public mutating func flushDrawRuns() {
    drawRunCache.clear()

    for gridID in grids.keys {
      grids[gridID]!.flushDrawRuns(font: font, appearance: appearance, drawRunCache: drawRunCache)
    }
  }
}
