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

public struct InstanceState {
  public init(
    process: Neovim.Process,
    bufferedUIEvents: [UIEvent] = [],
    rawOptions: OrderedDictionary<String, Value> = [:],
    font: NimsFont,
    title: String? = nil,
    highlights: IntKeyedDictionary<Highlight> = [:],
    defaultForegroundColor: NimsColor? = nil,
    defaultBackgroundColor: NimsColor? = nil,
    defaultSpecialColor: NimsColor? = nil,
    grids: IntKeyedDictionary<Grid> = [:],
    windows: IdentifiedArrayOf<Window> = [],
    floatingWindows: IdentifiedArrayOf<FloatingWindow> = [],
    modeInfo: ModeInfo? = nil,
    mode: Mode? = nil,
    cursor: Cursor? = nil,
    windowZIndexCounter: Int = 0,
    tabline: Tabline? = nil,
    cmdlines: IntKeyedDictionary<Cmdline> = [:],
    cmdlineUpdateFlag: Bool = true,
    instanceUpdateFlag: Bool = true,
    gridsLayoutUpdateFlag: Bool = true
  ) {
    self.process = process
    self.bufferedUIEvents = bufferedUIEvents
    self.rawOptions = rawOptions
    self.font = font
    self.title = title
    self.highlights = highlights
    self.defaultForegroundColor = defaultForegroundColor
    self.defaultBackgroundColor = defaultBackgroundColor
    self.defaultSpecialColor = defaultSpecialColor
    self.grids = grids
    self.windows = windows
    self.floatingWindows = floatingWindows
    self.modeInfo = modeInfo
    self.mode = mode
    self.cursor = cursor
    self.windowZIndexCounter = windowZIndexCounter
    self.tabline = tabline
    self.cmdlines = cmdlines
    self.cmdlineUpdateFlag = cmdlineUpdateFlag
    self.instanceUpdateFlag = instanceUpdateFlag
    self.gridsLayoutUpdateFlag = gridsLayoutUpdateFlag
  }

  public var process: Neovim.Process
  public var bufferedUIEvents: [UIEvent]
  public var rawOptions: OrderedDictionary<String, Value>
  public var font: NimsFont
  public var title: String?
  public var highlights: IntKeyedDictionary<Highlight>
  public var defaultForegroundColor: NimsColor?
  public var defaultBackgroundColor: NimsColor?
  public var defaultSpecialColor: NimsColor?
  public var grids: IntKeyedDictionary<Grid>
  public var windows: IdentifiedArrayOf<Window>
  public var floatingWindows: IdentifiedArrayOf<FloatingWindow>
  public var modeInfo: ModeInfo?
  public var mode: Mode?
  public var cursor: Cursor?
  public var windowZIndexCounter: Int
  public var tabline: Tabline?
  public var cmdlines: IntKeyedDictionary<Cmdline>
  public var cmdlineUpdateFlag: Bool
  public var instanceUpdateFlag: Bool
  public var gridsLayoutUpdateFlag: Bool

  public var outerGrid: Grid? {
    grids[.outer]
  }

  public mutating func nextWindowZIndex() -> Int {
    windowZIndexCounter += 1
    return windowZIndexCounter
  }
}