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
  public struct Debug: Sendable, Codable {
    public var isUIEventsLoggingEnabled: Bool = false
  }

  public enum GridUpdate: Sendable {
    case resize(IntegerSize)
    case clear
    case lines(IntKeyedDictionary<[UIEventsChunk.GridLine]>)
    case scroll(frame: IntegerRectangle, offset: IntegerSize)
    case destroy
    case winPos(windowID: Window.ID, frame: IntegerRectangle)
    case winFloatPos(windowID: Window.ID, anchor: FloatingWindow.Anchor, anchorGridID: Int, anchorOrigin: (column: Double, row: Double), isFocusable: Bool, zIndex: Int)
    case winExternalPos(windowID: Window.ID)
    case winHide
    case winClose
  }

  @PublicInit
  public struct Updates: Sendable {
    public var isDebugUpdated: Bool = false
    public var isModeUpdated: Bool = false
    public var isTitleUpdated: Bool = false
    public var font: Font? = nil
    public var appearance: Appearance? = nil
    public var updatedObservedHighlightNames: Set<Appearance.ObservedHighlightName> = []
    public var isCursorUpdated: Bool = false
    public var tabline: TablineUpdate = .init()
    public var isCmdlinesUpdated: Bool = false
    public var isMessagesUpdated: Bool = false
    public var gridsUpdates: [(gridID: Int, update: GridUpdate)] = []
    public var isPopupmenuUpdated: Bool = false
    public var isPopupmenuSelectionUpdated: Bool = false
    public var isCursorBlinkingPhaseUpdated: Bool = false
    public var isBusyUpdated: Bool = false
    public var isMouseOnUpdated: Bool = false

    public var isMouseUserInteractionEnabledUpdated: Bool {
      isMouseOnUpdated || isBusyUpdated
    }

    public var isFontUpdated: Bool {
      font != nil
    }

    public var isAppearanceUpdated: Bool {
      appearance != nil
    }

    public mutating func formUnion(_ updates: Updates) {
      isDebugUpdated = isDebugUpdated || updates.isDebugUpdated
      isModeUpdated = isModeUpdated || updates.isModeUpdated
      isTitleUpdated = isTitleUpdated || updates.isTitleUpdated
      font = updates.font
      appearance = updates.appearance
      updatedObservedHighlightNames.formUnion(updates.updatedObservedHighlightNames)
      isCursorUpdated = isCursorUpdated || updates.isCursorUpdated
      tabline.formUnion(updates.tabline)
      isCmdlinesUpdated = isCmdlinesUpdated || updates.isCmdlinesUpdated
      isMessagesUpdated = isMessagesUpdated || updates.isMessagesUpdated
      gridsUpdates += updates.gridsUpdates
      isPopupmenuUpdated = isPopupmenuUpdated || updates.isPopupmenuUpdated
      isPopupmenuSelectionUpdated = isPopupmenuSelectionUpdated || updates.isPopupmenuSelectionUpdated
      isCursorBlinkingPhaseUpdated = isCursorBlinkingPhaseUpdated || updates.isCursorBlinkingPhaseUpdated
      isBusyUpdated = isBusyUpdated || updates.isBusyUpdated
      isMouseOnUpdated = isMouseOnUpdated || updates.isMouseOnUpdated
    }
  }

  @PublicInit
  public struct TablineUpdate: Sendable {
    public var isTabpagesUpdated: Bool = false
    public var isTabpagesContentUpdated: Bool = false
    public var isBuffersUpdated: Bool = false
    public var isSelectedTabpageUpdated: Bool = false
    public var isSelectedBufferUpdated: Bool = false

    public mutating func formUnion(_ update: TablineUpdate) {
      isTabpagesUpdated = isTabpagesUpdated || update.isTabpagesUpdated
      isTabpagesContentUpdated = isTabpagesContentUpdated || update.isTabpagesContentUpdated
      isBuffersUpdated = isBuffersUpdated || update.isBuffersUpdated
      isSelectedTabpageUpdated = isSelectedTabpageUpdated || update.isSelectedTabpageUpdated
      isSelectedBufferUpdated = isSelectedBufferUpdated || update.isSelectedBufferUpdated
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
  public var cmdlines: Cmdlines = .init()
  public var msgShows: [MsgShow] = []
  public var isMsgShowsDismissed: Bool = false
  public var windowZIndexCounter: Int = 0
  public var popupmenu: Popupmenu? = nil
  public var cursorBlinkingPhase: Bool = true
  public var isBusy: Bool = false
  public var isMouseOn: Bool = true

  public var currentCursorStyle: CursorStyle? {
    guard let modeInfo, let mode, mode.cursorStyleIndex < modeInfo.cursorStyles.count else {
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

//  public func orderedGridIDs() -> [Grid.ID] {
//    grids
//      .map { $1 }
//      .sorted(by: { first, second in
//        if first.zIndex != second.zIndex {
//          first.zIndex < second.zIndex
//        } else {
//          first.id < second.id
//        }
//      })
//      .map(\.id)
//  }
//
//  public mutating func flushDrawRuns() {
//    for gridID in grids.keys {
//      grids[gridID]!.flushDrawRuns(font: font, appearance: appearance)
//    }
//  }
}
