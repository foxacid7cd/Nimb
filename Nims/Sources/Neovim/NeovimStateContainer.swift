// SPDX-License-Identifier: MIT

import CasePaths
import CustomDump
import IdentifiedCollections
import Library
import MessagePack
import Overture

@NeovimActor
public final class NeovimStateContainer {
  init(state: NeovimState = .init()) {
    self.state = state
  }

  public private(set) var state: NeovimState

  public func apply(uiEvents: [UIEvent]) async -> NeovimState.Updates {
    var updates = NeovimState.Updates()

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
      if let cursor = state.cursor, let style = state.currentCursorStyle {
        updatedText(inGridWithID: cursor.gridID, .cursor(style: style, position: cursor.position))
      }
    }

    func updatedLayout(forGridWithID gridID: Grid.ID) {
      updates.updatedLayoutGridIDs.insert(gridID)
    }

    func updatedText(inGridWithID gridID: Grid.ID, _ textUpdate: Grid.TextUpdate) {
      let font = state.font
      let appearance = state.appearance

      var textUpdateApplyResult: Grid.TextUpdateApplyResult?
      update(&state.grids[gridID]!) { grid in
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

    var uiEventsChunks = [UIEventsChunk]()
    for uiEvent in uiEvents {
      switch uiEvent {
      case let .gridLine(gridID, row, originColumn, data, wrap):
        let gridLine = UIEventsChunk.GridLine(row: row, originColumn: originColumn, data: data, wrap: wrap)

        if
          let previousChunk = uiEventsChunks.last,
          case .gridLines(let chunkGridID, var chunkGridLines) = previousChunk,
          chunkGridID == gridID
        {
          chunkGridLines.append(gridLine)
          uiEventsChunks[uiEventsChunks.count - 1] = .gridLines(gridID: gridID, gridLines: chunkGridLines)
        } else {
          uiEventsChunks.append(.gridLines(gridID: gridID, gridLines: [gridLine]))
        }

      default:
        uiEventsChunks.append(.single(uiEvent))
      }
    }

    for uiEventsChunk in uiEventsChunks {
      switch uiEventsChunk {
      case let .single(uiEvent):
        switch uiEvent {
        case let .setTitle(title):
          state.title = title

          titleUpdated()

        case let .modeInfoSet(enabled, cursorStyles):
          state.modeInfo = ModeInfo(
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
          state.rawOptions.updateValue(
            value,
            forKey: name,
            insertingAt: state.rawOptions.count
          )

        case let .modeChange(name, cursorStyleIndex):
          state.mode = .init(
            name: name,
            cursorStyleIndex: cursorStyleIndex
          )

          modeUpdated()

          if state.cursor != nil {
            cursorUpdated()
          }

        case let .defaultColorsSet(rgbFg, rgbBg, rgbSp, _, _):
          state.appearance.defaultForegroundColor = .init(rgb: rgbFg)
          state.appearance.defaultBackgroundColor = .init(rgb: rgbBg)
          state.appearance.defaultSpecialColor = .init(rgb: rgbSp)
          state.flushDrawRuns()

          appearanceUpdated()

        case let .hlAttrDefine(rawID, rgbAttrs, _, _):
          let noCombine = rgbAttrs["noCombine"]
            .flatMap((/Value.boolean).extract(from:)) ?? false

          let id = Highlight.ID(rawID)
          var highlight = (noCombine ? state.appearance.highlights[id] : nil) ?? .init(id: id)

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

          let isNewHighlight = state.appearance.highlights[id] == nil
          state.appearance.highlights[id] = highlight

          if !isNewHighlight {
            appearanceUpdated()
          }

        case let .gridResize(gridID, width, height):
          let size = IntegerSize(
            columnsCount: width,
            rowsCount: height
          )

          if state.grids[gridID] == nil {
            let cells = TwoDimensionalArray(size: size, repeatingElement: Cell.default)
            let layout = GridLayout(cells: cells)
            state.grids[gridID] = .init(
              id: gridID,
              layout: layout,
              drawRuns: .init(
                layout: layout,
                font: state.font,
                appearance: state.appearance
              ),
              associatedWindow: nil,
              isHidden: false
            )
          }

          if
            let cursor = state.cursor,
            cursor.gridID == gridID,
            cursor.position.column >= size.columnsCount,
            cursor.position.row >= size.rowsCount
          {
            state.cursor = nil

            cursorUpdated(oldCursor: cursor)
          }

          updatedLayout(forGridWithID: gridID)
          updatedText(inGridWithID: gridID, .resize(size))

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
          state.grids[gridID]?.associatedWindow = nil

          updatedLayout(forGridWithID: gridID)

        case let .gridCursorGoto(gridID, row, column):
          let oldCursor = state.cursor

          let cursorPosition = IntegerPoint(
            column: column,
            row: row
          )
          state.cursor = .init(
            gridID: gridID,
            position: cursorPosition
          )

          cursorUpdated(oldCursor: oldCursor)

        case let .winPos(gridID, windowID, originRow, originColumn, columnsCount, rowsCount):
          let zIndex = state.nextWindowZIndex()

          state.grids[gridID]?.associatedWindow = .plain(
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
          state.grids[gridID]?.isHidden = false

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

          let zIndex = state.nextWindowZIndex()

          state.grids[gridID]?.associatedWindow = .floating(
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
          state.grids[gridID]?.isHidden = false

          updatedLayout(forGridWithID: gridID)

        case let .winHide(gridID):
          state.grids[gridID]?.isHidden = true

          updatedLayout(forGridWithID: gridID)

        case let .winClose(gridID):
          state.grids[gridID]?.associatedWindow = nil

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
          if identifiedTabpages != state.tabline?.tabpages {
            if identifiedTabpages.count == state.tabline?.tabpages.count {
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
          if identifiedBuffers != state.tabline?.buffers {
            tablineBuffersUpdated()
          }

          if updates.tabline.isTabpagesUpdated || currentTabpageID != state.tabline?.currentTabpageID {
            tablineSelectedTabpageUpdated()
          }

          if updates.tabline.isBuffersUpdated || currentBufferID != state.tabline?.currentBufferID {
            tablineSelectedBufferUpdated()
          }

          state.tabline = .init(
            currentTabpageID: currentTabpageID,
            tabpages: identifiedTabpages,
            currentBufferID: currentBufferID,
            buffers: identifiedBuffers
          )

        case let .cmdlineShow(content, pos, firstc, prompt, indent, level):
          let oldCursor = state.cursor

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
          let oldCmdline = state.cmdlines.dictionary[level]

          state.cmdlines.lastCmdlineLevel = level

          if cmdline != oldCmdline {
            state.cmdlines.dictionary[level] = cmdline
            cursorUpdated(oldCursor: oldCursor)
            cmdlinesUpdated()
          }

        case let .cmdlinePos(pos, level):
          let oldCursor = state.cursor

          update(&state.cmdlines.dictionary[level]) {
            $0?.cursorPosition = pos
          }

          cursorUpdated(oldCursor: oldCursor)

        case let .cmdlineSpecialChar(c, shift, level):
          update(&state.cmdlines.dictionary[level]) {
            $0?.specialCharacter = c
            $0?.shiftAfterSpecialCharacter = shift
          }

          cmdlinesUpdated()

        case let .cmdlineHide(level):
          state.cmdlines.dictionary.removeValue(forKey: level)

          cursorUpdated()
          cmdlinesUpdated()

        case let .cmdlineBlockShow(rawLines):
          state.cmdlines.blockLines[state.cmdlines.lastCmdlineLevel!] = rawLines
            .map { blockLine(fromRawLine: $0) }

          cmdlinesUpdated()

        case let .cmdlineBlockAppend(rawLine):
          state.cmdlines.blockLines[state.cmdlines.lastCmdlineLevel!]!
            .append(blockLine(fromRawLine: .array(rawLine)))

          cmdlinesUpdated()

        case .cmdlineBlockHide:
          state.cmdlines.blockLines.removeValue(forKey: state.cmdlines.lastCmdlineLevel!)

          cmdlinesUpdated()

        case let .msgShow(rawKind, content, replaceLast):
          if replaceLast, !state.msgShows.isEmpty {
            state.msgShows.removeLast()
          }

          let kind = MsgShow.Kind(rawValue: rawKind)
          if kind == nil {
            assertionFailure(rawKind)
          }

          if !content.isEmpty {
            let msgShow = MsgShow(
              index: state.msgShows.count,
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
            state.msgShows.append(msgShow)
          }

          msgShowsUpdated()

        case .msgClear:
          if !state.msgShows.isEmpty {
            state.msgShows = []
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

          state.popupmenu = .init(items: items, selectedItemIndex: selectedItemIndex, anchor: anchor)

          popupmenuUpdated()

        case let .popupmenuSelect(selected):
          if state.popupmenu != nil {
            state.popupmenu!.selectedItemIndex = selected >= 0 ? selected : nil
            popupmenuSelectionUpdated()
          }

        case .popupmenuHide:
          if state.popupmenu != nil {
            state.popupmenu = nil
            popupmenuUpdated()
          }

        default:
          break
        }

      case let .gridLines(gridID, gridLines):
        let font = state.font
        let appearance = state.appearance
        let grid = state.grids[gridID]!

        await withTaskGroup(of: [Grid.LineUpdateResult].self) { taskGroup in
          for gridLines in Array(gridLines).chunks(ofCount: 10) {
            taskGroup.addTask {
              var accumulator = [Grid.LineUpdateResult]()

              for gridLine in gridLines {
                var cells = [Cell]()
                var highlightID = 0

                for value in gridLine.data {
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

                  let cell = Cell(text: text, highlightID: highlightID)
                  for _ in 0 ..< repeatCount {
                    cells.append(cell)
                  }
                }

                await accumulator.append(
                  grid.applyingLineUpdate(
                    forRow: gridLine.row,
                    originColumn: gridLine.originColumn,
                    cells: cells,
                    font: font,
                    appearance: appearance
                  )
                )
              }

              return accumulator
            }
          }

          for await lineUpdateResults in taskGroup {
            update(&state.grids[gridID]!) { grid in
              for lineUpdateResult in lineUpdateResults {
                grid.layout.cells.rows[lineUpdateResult.row] = lineUpdateResult.rowCells
                grid.layout.rowLayouts[lineUpdateResult.row] = lineUpdateResult.rowLayout
                grid.drawRuns.rowDrawRuns[lineUpdateResult.row] = lineUpdateResult.rowDrawRun

                if lineUpdateResult.shouldUpdateCursorDrawRun {
                  grid.drawRuns.cursorDrawRun!.updateParent(
                    with: grid.layout,
                    rowDrawRuns: grid.drawRuns.rowDrawRuns
                  )
                }
              }
            }

            update(&updates.gridUpdates[gridID]) { updates in
              let dirtyRectangles = lineUpdateResults.map(\.dirtyRectangle)

              switch updates {
              case var .dirtyRectangles(accumulator):
                accumulator += dirtyRectangles
                updates = .dirtyRectangles(accumulator)

              case .none:
                updates = .dirtyRectangles(dirtyRectangles)

              default:
                break
              }
            }
          }
        }
      }
    }

    return updates
  }

  public func apply(newFont: NimsFont) -> NeovimState.Updates {
    state.apply(newFont: newFont)
  }

  public func set(cursorBlinkingPhase: Bool) {
    state.cursorBlinkingPhase = cursorBlinkingPhase
  }
}