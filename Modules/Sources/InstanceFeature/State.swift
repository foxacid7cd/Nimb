// SPDX-License-Identifier: MIT

import Algorithms
import Collections
import ComposableArchitecture
import IdentifiedCollections
import Library
import MessagePack
import Neovim
import SwiftUI
import Tagged

public extension Instance {
  struct State: Equatable {
    public init(
      defaultFont: Font? = nil,
      bufferedUIEvents: [UIEvent] = [],
      rawOptions: OrderedDictionary<String, Value> = [:],
      font: Font? = nil,
      title: String? = nil,
      highlights: IdentifiedArrayOf<Highlight> = [],
      grids: IdentifiedArrayOf<Grid> = [],
      windows: IdentifiedArrayOf<Window> = [],
      floatingWindows: IdentifiedArrayOf<FloatingWindow> = [],
      modeInfo: ModeInfo? = nil,
      mode: Mode? = nil,
      cursor: Cursor? = nil,
      cursorBlinkingPhase: Bool = true,
      tabline: Tabline? = nil,
      cmdlines: IdentifiedArrayOf<Cmdline> = [],
      cmdlineUpdateFlag: Bool = false,
      windowZIndexCounter: Int = 0,
      instanceUpdateFlag: Bool = false,
      gridsLayoutUpdateFlag: Bool = false
    ) {
      self.defaultFont = defaultFont
      self.bufferedUIEvents = bufferedUIEvents
      self.rawOptions = rawOptions
      self.font = font
      self.title = title
      self.highlights = highlights
      self.grids = grids
      self.windows = windows
      self.modeInfo = modeInfo
      self.mode = mode
      self.cursor = cursor
      self.cursorBlinkingPhase = cursorBlinkingPhase
      self.tabline = tabline
      self.cmdlines = cmdlines
      self.cmdlineUpdateFlag = cmdlineUpdateFlag
      self.floatingWindows = floatingWindows
      self.windowZIndexCounter = windowZIndexCounter
      self.instanceUpdateFlag = instanceUpdateFlag
      self.gridsLayoutUpdateFlag = gridsLayoutUpdateFlag
    }

    public typealias ID = Tagged<State, String>

    public var defaultFont: Font?
    public var bufferedUIEvents: [UIEvent]
    public var rawOptions: OrderedDictionary<String, Value>
    public var font: Font?
    public var title: String?
    public var highlights: IdentifiedArrayOf<Highlight>
    public var grids: IdentifiedArrayOf<Grid>
    public var windows: IdentifiedArrayOf<Window>
    public var floatingWindows: IdentifiedArrayOf<FloatingWindow>
    public var modeInfo: ModeInfo?
    public var mode: Mode?
    public var cursor: Cursor?
    public var cursorBlinkingPhase: Bool
    public var windowZIndexCounter: Int
    public var tabline: Tabline?
    public var cmdlines: IdentifiedArrayOf<Cmdline>
    public var cmdlineUpdateFlag: Bool
    public var instanceUpdateFlag: Bool
    public var gridsLayoutUpdateFlag: Bool

    public var outerGrid: Grid? {
      grids[id: .outer]
    }

    public mutating func nextWindowZIndex() -> Int {
      windowZIndexCounter += 1
      return windowZIndexCounter
    }
  }
}
