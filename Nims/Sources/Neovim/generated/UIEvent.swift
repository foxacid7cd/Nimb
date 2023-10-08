// SPDX-License-Identifier: MIT

import CasePaths
import MessagePack

public enum UIEvent: Sendable, Equatable {
  case modeInfoSet(enabled: Bool, cursorStyles: [Value])
  case updateMenu
  case busyStart
  case busyStop
  case mouseOn
  case mouseOff
  case modeChange(mode: String, modeIDX: Int)
  case bell
  case visualBell
  case flush
  case suspend
  case setTitle(title: String)
  case setIcon(icon: String)
  case screenshot(path: String)
  case optionSet(name: String, value: Value)
  case updateFg(fg: Int)
  case updateBg(bg: Int)
  case updateSp(sp: Int)
  case resize(width: Int, height: Int)
  case clear
  case eolClear
  case cursorGoto(row: Int, col: Int)
  case highlightSet(attrs: [Value: Value])
  case put(str: String)
  case setScrollRegion(top: Int, bot: Int, left: Int, right: Int)
  case scroll(count: Int)
  case defaultColorsSet(rgbFg: Int, rgbBg: Int, rgbSp: Int, ctermFg: Int, ctermBg: Int)
  case hlAttrDefine(id: Int, rgbAttrs: [Value: Value], ctermAttrs: [Value: Value], info: [Value])
  case hlGroupSet(name: String, id: Int)
  case gridResize(grid: Int, width: Int, height: Int)
  case gridClear(grid: Int)
  case gridCursorGoto(grid: Int, row: Int, col: Int)
  case gridLine(grid: Int, row: Int, colStart: Int, data: [Value], wrap: Bool)
  case gridScroll(grid: Int, top: Int, bot: Int, left: Int, right: Int, rows: Int, cols: Int)
  case gridDestroy(grid: Int)
  case winPos(grid: Int, windowID: Window.ID, startrow: Int, startcol: Int, width: Int, height: Int)
  case winFloatPos(grid: Int, windowID: Window.ID, anchor: String, anchorGrid: Int, anchorRow: Double, anchorCol: Double, focusable: Bool, zindex: Int)
  case winExternalPos(grid: Int, windowID: Window.ID)
  case winHide(grid: Int)
  case winClose(grid: Int)
  case msgSetPos(grid: Int, row: Int, scrolled: Bool, sepChar: String)
  case winViewport(grid: Int, windowID: Window.ID, topline: Int, botline: Int, curline: Int, curcol: Int, lineCount: Int, scrollDelta: Int)
  case winExtmark(grid: Int, windowID: Window.ID, nsID: Int, markID: Int, row: Int, col: Int)
  case popupmenuShow(items: [Value], selected: Int, row: Int, col: Int, grid: Int)
  case popupmenuHide
  case popupmenuSelect(selected: Int)
  case tablineUpdate(tabpageID: Tabpage.ID, tabs: [Value], bufferID: Buffer.ID, buffers: [Value])
  case cmdlineShow(content: [Value], pos: Int, firstc: String, prompt: String, indent: Int, level: Int)
  case cmdlinePos(pos: Int, level: Int)
  case cmdlineSpecialChar(c: String, shift: Bool, level: Int)
  case cmdlineHide(level: Int)
  case cmdlineBlockShow(lines: [Value])
  case cmdlineBlockAppend(lines: [Value])
  case cmdlineBlockHide
  case wildmenuShow(items: [Value])
  case wildmenuSelect(selected: Int)
  case wildmenuHide
  case msgShow(kind: String, content: [Value], replaceLast: Bool)
  case msgClear
  case msgShowcmd(content: [Value])
  case msgShowmode(content: [Value])
  case msgRuler(content: [Value])
  case msgHistoryShow(entries: [Value])
  case msgHistoryClear
  case errorExit(status: Int)
}

public extension [UIEvent] {
  init(rawRedrawNotificationParameters: [Value]) throws {
    var accumulator = [UIEvent]()
    for rawParameter in rawRedrawNotificationParameters {
      guard let rawParameter = (/Value.array).extract(from: rawParameter) else {
        throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
      }
      guard let uiEventName = rawParameter.first.flatMap(/Value.string) else {
        throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
      }
      switch uiEventName {
      case "mode_info_set":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 2,
            let enabled = (/Value.boolean).extract(from: rawUIEventParameters[0]), let cursorStyles = (/Value.array).extract(from: rawUIEventParameters[1])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .modeInfoSet(enabled: enabled, cursorStyles: cursorStyles)
          )
        }
      case "update_menu":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.updateMenu)
        }
      case "busy_start":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.busyStart)
        }
      case "busy_stop":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.busyStop)
        }
      case "mouse_on":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.mouseOn)
        }
      case "mouse_off":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.mouseOff)
        }
      case "mode_change":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 2,
            let mode = (/Value.string).extract(from: rawUIEventParameters[0]), let modeIDX = (/Value.integer).extract(from: rawUIEventParameters[1])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .modeChange(mode: mode, modeIDX: modeIDX)
          )
        }
      case "bell":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.bell)
        }
      case "visual_bell":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.visualBell)
        }
      case "flush":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.flush)
        }
      case "suspend":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.suspend)
        }
      case "set_title":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let title = (/Value.string).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .setTitle(title: title)
          )
        }
      case "set_icon":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let icon = (/Value.string).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .setIcon(icon: icon)
          )
        }
      case "screenshot":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let path = (/Value.string).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .screenshot(path: path)
          )
        }
      case "option_set":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 2, let name = (/Value.string).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          let value = rawUIEventParameters[1]
          accumulator.append(
            .optionSet(name: name, value: value)
          )
        }
      case "update_fg":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let fg = (/Value.integer).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .updateFg(fg: fg)
          )
        }
      case "update_bg":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let bg = (/Value.integer).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .updateBg(bg: bg)
          )
        }
      case "update_sp":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let sp = (/Value.integer).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .updateSp(sp: sp)
          )
        }
      case "resize":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 2,
            let width = (/Value.integer).extract(from: rawUIEventParameters[0]), let height = (/Value.integer).extract(from: rawUIEventParameters[1])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .resize(width: width, height: height)
          )
        }
      case "clear":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.clear)
        }
      case "eol_clear":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.eolClear)
        }
      case "cursor_goto":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 2, let row = (/Value.integer).extract(from: rawUIEventParameters[0]), let col = (/Value.integer).extract(from: rawUIEventParameters[1]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .cursorGoto(row: row, col: col)
          )
        }
      case "highlight_set":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let attrs = (/Value.dictionary).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .highlightSet(attrs: attrs)
          )
        }
      case "put":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let str = (/Value.string).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .put(str: str)
          )
        }
      case "set_scroll_region":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 4, let top = (/Value.integer).extract(from: rawUIEventParameters[0]), let bot = (/Value.integer).extract(from: rawUIEventParameters[1]),
            let left = (/Value.integer).extract(from: rawUIEventParameters[2]), let right = (/Value.integer).extract(from: rawUIEventParameters[3])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .setScrollRegion(top: top, bot: bot, left: left, right: right)
          )
        }
      case "scroll":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let count = (/Value.integer).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .scroll(count: count)
          )
        }
      case "default_colors_set":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 5, let rgbFg = (/Value.integer).extract(from: rawUIEventParameters[0]), let rgbBg = (/Value.integer).extract(from: rawUIEventParameters[1]),
            let rgbSp = (/Value.integer).extract(from: rawUIEventParameters[2]), let ctermFg = (/Value.integer).extract(from: rawUIEventParameters[3]),
            let ctermBg = (/Value.integer).extract(from: rawUIEventParameters[4])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .defaultColorsSet(rgbFg: rgbFg, rgbBg: rgbBg, rgbSp: rgbSp, ctermFg: ctermFg, ctermBg: ctermBg)
          )
        }
      case "hl_attr_define":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 4, let id = (/Value.integer).extract(from: rawUIEventParameters[0]), let rgbAttrs = (/Value.dictionary).extract(from: rawUIEventParameters[1]),
            let ctermAttrs = (/Value.dictionary).extract(from: rawUIEventParameters[2]), let info = (/Value.array).extract(from: rawUIEventParameters[3])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .hlAttrDefine(id: id, rgbAttrs: rgbAttrs, ctermAttrs: ctermAttrs, info: info)
          )
        }
      case "hl_group_set":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 2, let name = (/Value.string).extract(from: rawUIEventParameters[0]), let id = (/Value.integer).extract(from: rawUIEventParameters[1]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .hlGroupSet(name: name, id: id)
          )
        }
      case "grid_resize":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 3, let grid = (/Value.integer).extract(from: rawUIEventParameters[0]), let width = (/Value.integer).extract(from: rawUIEventParameters[1]),
            let height = (/Value.integer).extract(from: rawUIEventParameters[2])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .gridResize(grid: grid, width: width, height: height)
          )
        }
      case "grid_clear":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let grid = (/Value.integer).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .gridClear(grid: grid)
          )
        }
      case "grid_cursor_goto":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 3, let grid = (/Value.integer).extract(from: rawUIEventParameters[0]), let row = (/Value.integer).extract(from: rawUIEventParameters[1]),
            let col = (/Value.integer).extract(from: rawUIEventParameters[2])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .gridCursorGoto(grid: grid, row: row, col: col)
          )
        }
      case "grid_line":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 5, let grid = (/Value.integer).extract(from: rawUIEventParameters[0]), let row = (/Value.integer).extract(from: rawUIEventParameters[1]),
            let colStart = (/Value.integer).extract(from: rawUIEventParameters[2]), let data = (/Value.array).extract(from: rawUIEventParameters[3]),
            let wrap = (/Value.boolean).extract(from: rawUIEventParameters[4])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .gridLine(grid: grid, row: row, colStart: colStart, data: data, wrap: wrap)
          )
        }
      case "grid_scroll":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 7, let grid = (/Value.integer).extract(from: rawUIEventParameters[0]), let top = (/Value.integer).extract(from: rawUIEventParameters[1]),
            let bot = (/Value.integer).extract(from: rawUIEventParameters[2]), let left = (/Value.integer).extract(from: rawUIEventParameters[3]),
            let right = (/Value.integer).extract(from: rawUIEventParameters[4]), let rows = (/Value.integer).extract(from: rawUIEventParameters[5]),
            let cols = (/Value.integer).extract(from: rawUIEventParameters[6])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .gridScroll(grid: grid, top: top, bot: bot, left: left, right: right, rows: rows, cols: cols)
          )
        }
      case "grid_destroy":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let grid = (/Value.integer).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .gridDestroy(grid: grid)
          )
        }
      case "win_pos":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 6,
            let grid = (/Value.integer).extract(from: rawUIEventParameters[0]), let windowID = (/Value.ext).extract(from: rawUIEventParameters[1])
              .flatMap(References.Window.init(type:data:)),
            let startrow = (/Value.integer).extract(from: rawUIEventParameters[2]), let startcol = (/Value.integer).extract(from: rawUIEventParameters[3]),
            let width = (/Value.integer).extract(from: rawUIEventParameters[4]), let height = (/Value.integer).extract(from: rawUIEventParameters[5])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .winPos(grid: grid, windowID: windowID, startrow: startrow, startcol: startcol, width: width, height: height)
          )
        }
      case "win_float_pos":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 8,
            let grid = (/Value.integer).extract(from: rawUIEventParameters[0]), let windowID = (/Value.ext).extract(from: rawUIEventParameters[1])
              .flatMap(References.Window.init(type:data:)),
            let anchor = (/Value.string).extract(from: rawUIEventParameters[2]), let anchorGrid = (/Value.integer).extract(from: rawUIEventParameters[3]),
            let anchorRow = (/Value.float).extract(from: rawUIEventParameters[4]), let anchorCol = (/Value.float).extract(from: rawUIEventParameters[5]),
            let focusable = (/Value.boolean).extract(from: rawUIEventParameters[6]), let zindex = (/Value.integer).extract(from: rawUIEventParameters[7])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .winFloatPos(grid: grid, windowID: windowID, anchor: anchor, anchorGrid: anchorGrid, anchorRow: anchorRow, anchorCol: anchorCol, focusable: focusable, zindex: zindex)
          )
        }
      case "win_external_pos":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 2,
            let grid = (/Value.integer).extract(from: rawUIEventParameters[0]), let windowID = (/Value.ext).extract(from: rawUIEventParameters[1])
              .flatMap(References.Window.init(type:data:))
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .winExternalPos(grid: grid, windowID: windowID)
          )
        }
      case "win_hide":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let grid = (/Value.integer).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .winHide(grid: grid)
          )
        }
      case "win_close":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let grid = (/Value.integer).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .winClose(grid: grid)
          )
        }
      case "msg_set_pos":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 4, let grid = (/Value.integer).extract(from: rawUIEventParameters[0]), let row = (/Value.integer).extract(from: rawUIEventParameters[1]),
            let scrolled = (/Value.boolean).extract(from: rawUIEventParameters[2]), let sepChar = (/Value.string).extract(from: rawUIEventParameters[3])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .msgSetPos(grid: grid, row: row, scrolled: scrolled, sepChar: sepChar)
          )
        }
      case "win_viewport":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 8,
            let grid = (/Value.integer).extract(from: rawUIEventParameters[0]), let windowID = (/Value.ext).extract(from: rawUIEventParameters[1])
              .flatMap(References.Window.init(type:data:)),
            let topline = (/Value.integer).extract(from: rawUIEventParameters[2]), let botline = (/Value.integer).extract(from: rawUIEventParameters[3]),
            let curline = (/Value.integer).extract(from: rawUIEventParameters[4]), let curcol = (/Value.integer).extract(from: rawUIEventParameters[5]),
            let lineCount = (/Value.integer).extract(from: rawUIEventParameters[6]), let scrollDelta = (/Value.integer).extract(from: rawUIEventParameters[7])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .winViewport(grid: grid, windowID: windowID, topline: topline, botline: botline, curline: curline, curcol: curcol, lineCount: lineCount, scrollDelta: scrollDelta)
          )
        }
      case "win_extmark":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 6,
            let grid = (/Value.integer).extract(from: rawUIEventParameters[0]), let windowID = (/Value.ext).extract(from: rawUIEventParameters[1])
              .flatMap(References.Window.init(type:data:)),
            let nsID = (/Value.integer).extract(from: rawUIEventParameters[2]), let markID = (/Value.integer).extract(from: rawUIEventParameters[3]),
            let row = (/Value.integer).extract(from: rawUIEventParameters[4]), let col = (/Value.integer).extract(from: rawUIEventParameters[5])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .winExtmark(grid: grid, windowID: windowID, nsID: nsID, markID: markID, row: row, col: col)
          )
        }
      case "popupmenu_show":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 5, let items = (/Value.array).extract(from: rawUIEventParameters[0]), let selected = (/Value.integer).extract(from: rawUIEventParameters[1]),
            let row = (/Value.integer).extract(from: rawUIEventParameters[2]), let col = (/Value.integer).extract(from: rawUIEventParameters[3]),
            let grid = (/Value.integer).extract(from: rawUIEventParameters[4])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .popupmenuShow(items: items, selected: selected, row: row, col: col, grid: grid)
          )
        }
      case "popupmenu_hide":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.popupmenuHide)
        }
      case "popupmenu_select":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let selected = (/Value.integer).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .popupmenuSelect(selected: selected)
          )
        }
      case "tabline_update":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 4,
            let tabpageID = (/Value.ext).extract(from: rawUIEventParameters[0]).flatMap(References.Tabpage.init(type:data:)), let tabs = (/Value.array)
              .extract(from: rawUIEventParameters[1]),
            let bufferID = (/Value.ext).extract(from: rawUIEventParameters[2]).flatMap(References.Buffer.init(type:data:)), let buffers = (/Value.array)
              .extract(from: rawUIEventParameters[3])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .tablineUpdate(tabpageID: tabpageID, tabs: tabs, bufferID: bufferID, buffers: buffers)
          )
        }
      case "cmdline_show":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 6, let content = (/Value.array).extract(from: rawUIEventParameters[0]), let pos = (/Value.integer).extract(from: rawUIEventParameters[1]),
            let firstc = (/Value.string).extract(from: rawUIEventParameters[2]), let prompt = (/Value.string).extract(from: rawUIEventParameters[3]),
            let indent = (/Value.integer).extract(from: rawUIEventParameters[4]), let level = (/Value.integer).extract(from: rawUIEventParameters[5])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .cmdlineShow(content: content, pos: pos, firstc: firstc, prompt: prompt, indent: indent, level: level)
          )
        }
      case "cmdline_pos":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 2, let pos = (/Value.integer).extract(from: rawUIEventParameters[0]), let level = (/Value.integer).extract(from: rawUIEventParameters[1]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .cmdlinePos(pos: pos, level: level)
          )
        }
      case "cmdline_special_char":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 3, let c = (/Value.string).extract(from: rawUIEventParameters[0]), let shift = (/Value.boolean).extract(from: rawUIEventParameters[1]),
            let level = (/Value.integer).extract(from: rawUIEventParameters[2])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .cmdlineSpecialChar(c: c, shift: shift, level: level)
          )
        }
      case "cmdline_hide":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let level = (/Value.integer).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .cmdlineHide(level: level)
          )
        }
      case "cmdline_block_show":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let lines = (/Value.array).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .cmdlineBlockShow(lines: lines)
          )
        }
      case "cmdline_block_append":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let lines = (/Value.array).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .cmdlineBlockAppend(lines: lines)
          )
        }
      case "cmdline_block_hide":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.cmdlineBlockHide)
        }
      case "wildmenu_show":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let items = (/Value.array).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .wildmenuShow(items: items)
          )
        }
      case "wildmenu_select":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let selected = (/Value.integer).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .wildmenuSelect(selected: selected)
          )
        }
      case "wildmenu_hide":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.wildmenuHide)
        }
      case "msg_show":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard
            rawUIEventParameters.count == 3, let kind = (/Value.string).extract(from: rawUIEventParameters[0]), let content = (/Value.array).extract(from: rawUIEventParameters[1]),
            let replaceLast = (/Value.boolean).extract(from: rawUIEventParameters[2])
          else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .msgShow(kind: kind, content: content, replaceLast: replaceLast)
          )
        }
      case "msg_clear":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.msgClear)
        }
      case "msg_showcmd":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let content = (/Value.array).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .msgShowcmd(content: content)
          )
        }
      case "msg_showmode":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let content = (/Value.array).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .msgShowmode(content: content)
          )
        }
      case "msg_ruler":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let content = (/Value.array).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .msgRuler(content: content)
          )
        }
      case "msg_history_show":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let entries = (/Value.array).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .msgHistoryShow(entries: entries)
          )
        }
      case "msg_history_clear":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.isEmpty else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(.msgHistoryClear)
        }
      case "error_exit":
        for rawUIEvent in rawParameter.dropFirst() {
          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          guard rawUIEventParameters.count == 1, let status = (/Value.integer).extract(from: rawUIEventParameters[0]) else {
            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
          }
          accumulator.append(
            .errorExit(status: status)
          )
        }
      default:
        throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
      }
    }
    self = accumulator
  }
}

public struct UIEventsDecodingFailure: Error {
  public init(_ rawRedrawNotificationParameters: [Value], lineNumber: UInt = #line) {
    self.rawRedrawNotificationParameters = rawRedrawNotificationParameters
    self.lineNumber = lineNumber
  }

  public var rawRedrawNotificationParameters: [Value]
  public var lineNumber: UInt
}
