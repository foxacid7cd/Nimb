// SPDX-License-Identifier: MIT

import CasePaths
import Collections
import CustomDump
import IdentifiedCollections
import Library
import MessagePack
import Overture

@PublicInit
public struct NeovimState: Sendable {
  public var bufferedUIEvents: [UIEvent] = []
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

  @NeovimActor
  public mutating func flushDrawRuns() {
    for gridID in grids.keys {
      grids[gridID]!.flushDrawRuns(font: font, appearance: appearance)
    }
  }
}

public extension NeovimState {
  @PublicInit
  struct Updates: Sendable {
    public var isModeUpdated: Bool = false
    public var isTitleUpdated: Bool = false
    public var isFontUpdated: Bool = false
    public var isAppearanceUpdated: Bool = false
    public var isCursorUpdated: Bool = false
    public var tabline: TablineUpdate = .init()
    public var isCmdlinesUpdated: Bool = false
    public var isMsgShowsUpdated: Bool = false
    public var updatedLayoutGridIDs: Set<Grid.ID> = []
    public var gridUpdates: [Grid.ID: GridUpdate] = [:]
    public var isPopupmenuUpdated: Bool = false
    public var isPopupmenuSelectionUpdated: Bool = false
    public var isCursorBlinkingPhaseUpdated: Bool = false

    public var isOuterGridLayoutUpdated: Bool {
      updatedLayoutGridIDs.contains(Grid.OuterID)
    }
  }

  @PublicInit
  struct TablineUpdate: Sendable {
    public var isTabpagesUpdated: Bool = false
    public var isTabpagesContentUpdated: Bool = false
    public var isBuffersUpdated: Bool = false
    public var isSelectedTabpageUpdated: Bool = false
    public var isSelectedBufferUpdated: Bool = false
  }

  enum GridUpdate: Sendable {
    case dirtyRectangles([IntegerRectangle])
    case needsDisplay

    mutating func apply(textUpdateApplyResult: Grid.TextUpdateApplyResult) {
      switch (self, textUpdateApplyResult) {
      case (.dirtyRectangles(var accumulator), let .dirtyRectangle(dirtyRectangle)):
        accumulator.append(dirtyRectangle)
        self = .dirtyRectangles(accumulator)

      case (_, .needsDisplay):
        self = .needsDisplay

      default:
        break
      }
    }
  }

  @NeovimActor
  mutating func apply(uiEvents: [UIEvent]) -> Updates? {
    bufferedUIEvents += uiEvents

    if uiEvents.last.flatMap(/UIEvent.flush) != nil {
      var updates = Updates()

      func modeUpdated() {
        updates.isModeUpdated = true
      }

      func titleUpdated() {
        updates.isTitleUpdated = true
      }

      func appearanceUpdated() {
        updates.isAppearanceUpdated = true
      }

      func tablineTabpagesUpdated() {
        updates.tabline.isTabpagesUpdated = true
      }

      func tablineTabpagesContentUpdated() {
        updates.tabline.isTabpagesContentUpdated = true
      }

      func tablineBuffersUpdated() {
        updates.tabline.isBuffersUpdated = true
      }

      func tablineSelectedTabpageUpdated() {
        updates.tabline.isSelectedTabpageUpdated = true
      }

      func tablineSelectedBufferUpdated() {
        updates.tabline.isSelectedBufferUpdated = true
      }

      func cmdlinesUpdated() {
        updates.isCmdlinesUpdated = true
      }

      func msgShowsUpdated() {
        updates.isMsgShowsUpdated = true
      }

      func cursorUpdated(oldCursor: Cursor? = nil) {
        if let oldCursor {
          updatedText(inGridWithID: oldCursor.gridID, .clearCursor)
        }
        updates.isCursorUpdated = true
        if let cursor, let style = currentCursorStyle {
          updatedText(inGridWithID: cursor.gridID, .cursor(style: style, position: cursor.position))
        }
      }

      func updatedLayout(forGridWithID gridID: Grid.ID) {
        updates.updatedLayoutGridIDs.insert(gridID)
      }

      func updatedText(inGridWithID gridID: Grid.ID, _ textUpdate: Grid.TextUpdate) {
        let font = font
        let appearance = appearance

        var textUpdateApplyResult: Grid.TextUpdateApplyResult?
        update(&grids[gridID]!) { grid in
          textUpdateApplyResult = grid.apply(
            textUpdate: textUpdate,
            font: font,
            appearance: appearance
          )
        }
        if let textUpdateApplyResult {
          update(&updates.gridUpdates[gridID]) { gridUpdate in
            if gridUpdate == nil {
              gridUpdate = .dirtyRectangles([])
            }
            gridUpdate!.apply(textUpdateApplyResult: textUpdateApplyResult)
          }
        }
      }

      func popupmenuUpdated() {
        updates.isPopupmenuUpdated = true
      }

      func popupmenuSelectionUpdated() {
        updates.isPopupmenuSelectionUpdated = true
      }

      func blockLine(fromRawLine rawLine: Value) -> [Cmdline.ContentPart] {
        guard case let .array(rawLine) = rawLine else {
          assertionFailure(rawLine)
          return []
        }

        var contentParts = [Cmdline.ContentPart]()

        for rawContentPart in rawLine {
          guard
            case let .array(rawContentPart) = rawContentPart,
            rawContentPart.count == 2,
            case let .integer(rawHighlightID) = rawContentPart[0],
            case let .string(text) = rawContentPart[1]
          else {
            assertionFailure(rawContentPart)
            return []
          }

          contentParts.append(
            .init(
              highlightID: .init(rawHighlightID),
              text: text
            )
          )
        }

        return contentParts
      }

      for uiEvent in bufferedUIEvents {
        switch uiEvent {
        case let .setTitle(title):
          self.title = title

          titleUpdated()

        case let .modeInfoSet(enabled, cursorStyles):
          modeInfo = ModeInfo(
            enabled: enabled,
            cursorStyles: cursorStyles
              .compactMap { rawCursorStyle -> CursorStyle? in
                guard case let .dictionary(rawCursorStyle) = rawCursorStyle else {
                  assertionFailure(rawCursorStyle)
                  return nil
                }

                return CursorStyle(
                  name: rawCursorStyle["name"]
                    .flatMap((/Value.string).extract(from:)),
                  shortName: rawCursorStyle["short_name"]
                    .flatMap((/Value.string).extract(from:)),
                  mouseShape: rawCursorStyle["mouse_shape"]
                    .flatMap((/Value.integer).extract(from:)),
                  blinkOn: rawCursorStyle["blinkon"]
                    .flatMap((/Value.integer).extract(from:)),
                  blinkOff: rawCursorStyle["blinkoff"]
                    .flatMap((/Value.integer).extract(from:)),
                  blinkWait: rawCursorStyle["blinkwait"]
                    .flatMap((/Value.integer).extract(from:)),
                  cellPercentage: rawCursorStyle["cell_percentage"]
                    .flatMap((/Value.integer).extract(from:)),
                  cursorShape: rawCursorStyle["cursor_shape"]
                    .flatMap((/Value.string).extract(from:))
                    .flatMap(CursorShape.init(rawValue:)),
                  idLm: rawCursorStyle["id_lm"]
                    .flatMap((/Value.integer).extract(from:)),
                  attrID: rawCursorStyle["attr_id"]
                    .flatMap((/Value.integer).extract(from:)),
                  attrIDLm: rawCursorStyle["attr_id_lm"]
                    .flatMap((/Value.integer).extract(from:))
                )
              }
          )

          cursorUpdated()

        case let .optionSet(name, value):
          rawOptions.updateValue(
            value,
            forKey: name,
            insertingAt: rawOptions.count
          )

        case let .modeChange(name, cursorStyleIndex):
          mode = .init(
            name: name,
            cursorStyleIndex: cursorStyleIndex
          )

          modeUpdated()

          if cursor != nil {
            cursorUpdated()
          }

        case let .defaultColorsSet(rgbFg, rgbBg, rgbSp, _, _):
          appearance.defaultForegroundColor = .init(rgb: rgbFg)
          appearance.defaultBackgroundColor = .init(rgb: rgbBg)
          appearance.defaultSpecialColor = .init(rgb: rgbSp)
          flushDrawRuns()

          appearanceUpdated()

        case let .hlAttrDefine(rawID, rgbAttrs, _, _):
          let noCombine = rgbAttrs["noCombine"]
            .flatMap((/Value.boolean).extract(from:)) ?? false

          let id = Highlight.ID(rawID)
          var highlight = (noCombine ? appearance.highlights[id] : nil) ?? .init(id: id)

          for (key, value) in rgbAttrs {
            guard case let .string(key) = key else {
              continue
            }

            switch key {
            case "foreground":
              if case let .integer(value) = value {
                highlight.foregroundColor = .init(rgb: value)
              }

            case "background":
              if case let .integer(value) = value {
                highlight.backgroundColor = .init(rgb: value)
              }

            case "special":
              if case let .integer(value) = value {
                highlight.specialColor = .init(rgb: value)
              }

            case "reverse":
              if case let .boolean(value) = value {
                highlight.isReverse = value
              }

            case "italic":
              if case let .boolean(value) = value {
                highlight.isItalic = value
              }

            case "bold":
              if case let .boolean(value) = value {
                highlight.isBold = value
              }

            case "strikethrough":
              if case let .boolean(value) = value {
                highlight.decorations.isStrikethrough = value
              }

            case "underline":
              if case let .boolean(value) = value {
                highlight.decorations.isUnderline = value
              }

            case "undercurl":
              if case let .boolean(value) = value {
                highlight.decorations.isUndercurl = value
              }

            case "underdouble":
              if case let .boolean(value) = value {
                highlight.decorations.isUnderdouble = value
              }

            case "underdotted":
              if case let .boolean(value) = value {
                highlight.decorations.isUnderdotted = value
              }

            case "underdashed":
              if case let .boolean(value) = value {
                highlight.decorations.isUnderdashed = value
              }

            case "blend":
              if case let .integer(value) = value {
                highlight.blend = value
              }

            case "bg_indexed",
                 "fg_indexed",
                 "nocombine",
                 "standout":
              continue

            default:
              assertionFailure(key)
            }
          }

          appearance.highlights[id] = highlight

        case let .gridResize(gridID, width, height):
          let size = IntegerSize(
            columnsCount: width,
            rowsCount: height
          )

          if grids[gridID] == nil {
            let cells = TwoDimensionalArray(size: size, repeatingElement: Cell.default)
            let layout = GridLayout(cells: cells)
            let drawRunsProvider = DrawRunsCachingProvider()
            grids[gridID] = .init(
              id: gridID,
              layout: layout,
              drawRunsProvider: drawRunsProvider,
              drawRuns: .init(
                layout: layout,
                font: font,
                appearance: appearance,
                drawRunsProvider: drawRunsProvider
              ),
              associatedWindow: nil,
              isHidden: false
            )
          }

          if
            let cursor,
            cursor.gridID == gridID,
            cursor.position.column >= size.columnsCount,
            cursor.position.row >= size.rowsCount
          {
            self.cursor = nil

            cursorUpdated(oldCursor: cursor)
          }

          updatedLayout(forGridWithID: gridID)
          updatedText(inGridWithID: gridID, .resize(size))

        case let .gridLine(gridID, row, startColumn, data, _):
          var cells = [Cell]()
          var highlightID = 0

          for value in data {
            guard
              let arrayValue = (/Value.array).extract(from: value),
              !arrayValue.isEmpty,
              let text = (/Value.string).extract(from: arrayValue[0])
            else {
              assertionFailure(value)
              continue
            }

            var repeatCount = 1

            if arrayValue.count > 1 {
              guard
                let newHighlightID = (/Value.integer).extract(from: arrayValue[1])
              else {
                assertionFailure(arrayValue)
                continue
              }

              highlightID = newHighlightID

              if arrayValue.count > 2 {
                guard
                  let newRepeatCount = (/Value.integer).extract(from: arrayValue[2])
                else {
                  assertionFailure(arrayValue)
                  continue
                }

                repeatCount = newRepeatCount
              }
            }

            for _ in 0 ..< repeatCount {
              cells.append(.init(
                text: text,
                highlightID: highlightID
              ))
            }
          }

          updatedText(inGridWithID: gridID, .line(origin: .init(column: startColumn, row: row), cells: cells))

        case let .gridScroll(gridID, top, bottom, left, right, rowsCount, columnsCount):
          let rectangle = IntegerRectangle(
            origin: .init(column: left, row: top),
            size: .init(columnsCount: right - left, rowsCount: bottom - top)
          )
          let offset = IntegerSize(columnsCount: columnsCount, rowsCount: rowsCount)
          updatedText(inGridWithID: gridID, .scroll(rectangle: rectangle, offset: offset))

        case let .gridClear(gridID):
          updatedText(inGridWithID: gridID, .clear)

        case let .gridDestroy(gridID):
          grids[gridID]?.associatedWindow = nil

          updatedLayout(forGridWithID: gridID)

        case let .gridCursorGoto(gridID, row, column):
          let oldCursor = cursor

          let cursorPosition = IntegerPoint(
            column: column,
            row: row
          )
          cursor = .init(
            gridID: gridID,
            position: cursorPosition
          )

          cursorUpdated(oldCursor: oldCursor)

        case let .winPos(gridID, windowID, originRow, originColumn, columnsCount, rowsCount):
          let zIndex = nextWindowZIndex()

          grids[gridID]?.associatedWindow = .plain(
            .init(
              id: windowID,
              frame: .init(
                origin: .init(
                  column: originColumn,
                  row: originRow
                ),
                size: .init(
                  columnsCount: columnsCount,
                  rowsCount: rowsCount
                )
              ),
              zIndex: zIndex
            )
          )
          grids[gridID]?.isHidden = false

          updatedLayout(forGridWithID: gridID)

        case let .winFloatPos(
          gridID,
          windowID,
          rawAnchor,
          rawAnchorGridID,
          anchorRow,
          anchorColumn,
          isFocusable,
          _
        ):
          guard let anchor = FloatingWindow.Anchor(rawValue: rawAnchor) else {
            assertionFailure(rawAnchor)
            continue
          }

          let zIndex = nextWindowZIndex()

          grids[gridID]?.associatedWindow = .floating(
            .init(
              id: windowID,
              anchor: anchor,
              anchorGridID: .init(rawAnchorGridID),
              anchorRow: anchorRow,
              anchorColumn: anchorColumn,
              isFocusable: isFocusable,
              zIndex: zIndex
            )
          )
          grids[gridID]?.isHidden = false

          updatedLayout(forGridWithID: gridID)

        case let .winHide(gridID):
          grids[gridID]?.isHidden = true

          updatedLayout(forGridWithID: gridID)

        case let .winClose(gridID):
          grids[gridID]?.associatedWindow = nil

          updatedLayout(forGridWithID: gridID)

        case let .tablineUpdate(currentTabpageID, rawTabpages, currentBufferID, rawBuffers):
          let tabpages = rawTabpages
            .compactMap { rawTabpage -> Tabpage? in
              guard
                case let .dictionary(rawTabpage) = rawTabpage,
                let rawID = rawTabpage["tab"]
                  .flatMap((/Value.ext).extract(from:)),
                let name = rawTabpage["name"]
                  .flatMap((/Value.string).extract(from:))
              else {
                assertionFailure("Invalid tabline raw value")
                return nil
              }

              return .init(
                id: .init(
                  type: rawID.0,
                  data: rawID.1
                )!,
                name: name
              )
            }
          let identifiedTabpages = IdentifiedArray(uniqueElements: tabpages)
          if identifiedTabpages != tabline?.tabpages {
            if identifiedTabpages.count == tabline?.tabpages.count {
              tablineTabpagesContentUpdated()
            } else {
              tablineTabpagesUpdated()
            }
          }

          let buffers = rawBuffers
            .compactMap { rawBuffer -> Buffer? in
              guard
                case let .dictionary(rawBuffer) = rawBuffer,
                let rawID = rawBuffer["buffer"]
                  .flatMap((/Value.ext).extract(from:)),
                let name = rawBuffer["name"]
                  .flatMap((/Value.string).extract(from:))
              else {
                assertionFailure(rawBuffer)
                return nil
              }

              return .init(
                id: .init(
                  type: rawID.0,
                  data: rawID.1
                )!,
                name: name
              )
            }
          let identifiedBuffers = IdentifiedArray(uniqueElements: buffers)
          if identifiedBuffers != tabline?.buffers {
            tablineBuffersUpdated()
          }

          if updates.tabline.isTabpagesUpdated || currentTabpageID != tabline?.currentTabpageID {
            tablineSelectedTabpageUpdated()
          }

          if updates.tabline.isBuffersUpdated || currentBufferID != tabline?.currentBufferID {
            tablineSelectedBufferUpdated()
          }

          tabline = .init(
            currentTabpageID: currentTabpageID,
            tabpages: identifiedTabpages,
            currentBufferID: currentBufferID,
            buffers: identifiedBuffers
          )

        case let .cmdlineShow(content, pos, firstc, prompt, indent, level):
          let oldCursor = cursor

          let cmdline = Cmdline(
            contentParts: content
              .compactMap { rawContentPart in
                guard
                  case let .array(rawContentPart) = rawContentPart,
                  rawContentPart.count == 2,
                  case let .integer(rawHighlightID) = rawContentPart[0],
                  case let .string(text) = rawContentPart[1]
                else {
                  assertionFailure(rawContentPart)
                  return nil
                }

                return .init(
                  highlightID: .init(rawHighlightID),
                  text: text
                )
              },
            cursorPosition: pos,
            firstCharacter: firstc,
            prompt: prompt,
            indent: indent,
            level: level,
            specialCharacter: "",
            shiftAfterSpecialCharacter: false
          )
          let oldCmdline = cmdlines.dictionary[level]

          cmdlines.lastCmdlineLevel = level

          if cmdline != oldCmdline {
            cmdlines.dictionary[level] = cmdline
            cursorUpdated(oldCursor: oldCursor)
            cmdlinesUpdated()
          }

        case let .cmdlinePos(pos, level):
          let oldCursor = cursor

          update(&cmdlines.dictionary[level]) {
            $0?.cursorPosition = pos
          }

          cursorUpdated(oldCursor: oldCursor)

        case let .cmdlineSpecialChar(c, shift, level):
          update(&cmdlines.dictionary[level]) {
            $0?.specialCharacter = c
            $0?.shiftAfterSpecialCharacter = shift
          }

          cmdlinesUpdated()

        case let .cmdlineHide(level):
          cmdlines.dictionary.removeValue(forKey: level)

          cursorUpdated()
          cmdlinesUpdated()

        case let .cmdlineBlockShow(rawLines):
          cmdlines.blockLines[cmdlines.lastCmdlineLevel!] = rawLines
            .map { blockLine(fromRawLine: $0) }

          cmdlinesUpdated()

        case let .cmdlineBlockAppend(rawLine):
          cmdlines.blockLines[cmdlines.lastCmdlineLevel!]!
            .append(blockLine(fromRawLine: .array(rawLine)))

          cmdlinesUpdated()

        case .cmdlineBlockHide:
          cmdlines.blockLines.removeValue(forKey: cmdlines.lastCmdlineLevel!)

          cmdlinesUpdated()

        case let .msgShow(rawKind, content, replaceLast):
          if replaceLast, !msgShows.isEmpty {
            msgShows.removeLast()
          }

          let kind = MsgShow.Kind(rawValue: rawKind)
          if kind == nil {
            assertionFailure(rawKind)
          }

          if !content.isEmpty {
            let msgShow = MsgShow(
              index: msgShows.count,
              kind: kind ?? .empty,
              contentParts: content
                .compactMap { rawContentPart in
                  guard
                    case let .array(rawContentPart) = rawContentPart,
                    rawContentPart.count == 2,
                    case let .integer(rawHighlightID) = rawContentPart[0],
                    case let .string(text) = rawContentPart[1]
                  else {
                    assertionFailure(rawContentPart)
                    return nil
                  }

                  return .init(
                    highlightID: .init(rawHighlightID),
                    text: text
                  )
                }
            )
            msgShows.append(msgShow)
          }

          msgShowsUpdated()

        case .msgClear:
          if !msgShows.isEmpty {
            msgShows = []
            msgShowsUpdated()
          }

        case let .popupmenuShow(rawItems, selected, row, col, gridID):
          var items = [PopupmenuItem]()

          for rawItem in rawItems {
            if let item = PopupmenuItem(rawItem: rawItem) {
              items.append(item)

            } else {
              assertionFailure(rawItem)

              items.append(.init(word: "-", kind: "-", menu: "", info: ""))
            }
          }

          let selectedItemIndex: Int? = selected >= 0 ? selected : nil

          let anchor: Popupmenu.Anchor = switch gridID {
          case -1:
            .cmdline(location: col)

          default:
            .grid(id: gridID, origin: .init(column: col, row: row))
          }

          popupmenu = .init(items: items, selectedItemIndex: selectedItemIndex, anchor: anchor)

          popupmenuUpdated()

        case let .popupmenuSelect(selected):
          if popupmenu != nil {
            popupmenu!.selectedItemIndex = selected >= 0 ? selected : nil
            popupmenuSelectionUpdated()
          }

        case .popupmenuHide:
          if popupmenu != nil {
            popupmenu = nil
            popupmenuUpdated()
          }

        default:
          continue
        }
      }

      bufferedUIEvents = []

      return updates
    }

    return nil
  }

  @NeovimActor
  mutating func apply(newFont: NimsFont) -> Updates {
    font = newFont
    flushDrawRuns()
    return .init(isFontUpdated: true)
  }
}
