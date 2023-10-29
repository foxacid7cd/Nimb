// SPDX-License-Identifier: MIT

import CasePaths
import CustomDump
import IdentifiedCollections
import Library
import MessagePack
import Overture

@StateActor
public final class NeovimStateContainer {
  init(state: NeovimState = .init()) {
    self.state = state
  }

  public var state: NeovimState

  public func apply(uiEvents: [UIEvent]) async -> NeovimState.Updates {
    var updates = NeovimState.Updates()

    func modeUpdated() {
      updates.isModeUpdated = true
    }

    func titleUpdated() {
      updates.isTitleUpdated = true
    }

    func appearanceUpdated() {
      if !updates.isAppearanceUpdated {
        state.drawRunCache.clear()
        updates.isAppearanceUpdated = true
      }
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
        apply(update: .clearCursor, toGridWithID: oldCursor.gridID)
      }
      if let cursor = state.cursor, let style = state.currentCursorStyle {
        apply(update: .cursor(style: style, position: cursor.position), toGridWithID: cursor.gridID)
      }
      updates.isCursorUpdated = true
    }

    func updatedLayout(forGridWithID gridID: Grid.ID) {
      updates.updatedLayoutGridIDs.insert(gridID)
    }

    func apply(update: Grid.Update, toGridWithID gridID: Grid.ID) {
      let font = state.font
      let appearance = state.appearance

      let result = state.grids[gridID]!.apply(
        update: update,
        font: font,
        appearance: appearance,
        drawRunCache: state.drawRunCache
      )
      if let result {
        Overture.update(&updates.gridUpdates[gridID]) { gridUpdate in
          if gridUpdate == nil {
            gridUpdate = .dirtyRectangles([])
          }
          gridUpdate!.formUnion(result)
        }
      }
    }

    func popupmenuUpdated() {
      updates.isPopupmenuUpdated = true
    }

    func popupmenuSelectionUpdated() {
      updates.isPopupmenuSelectionUpdated = true
    }

    func isBusyUpdated() {
      updates.isBusyUpdated = true
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
        let gridLine = UIEventsChunk.GridLine(originColumn: originColumn, data: data, wrap: wrap)

        if
          let previousChunk = uiEventsChunks.last,
          case .gridLines(let chunkGridID, let hlAttrDefines, var chunkGridLines) = previousChunk,
          chunkGridID == gridID
        {
          update(&chunkGridLines[row]) { rowGridLines in
            if rowGridLines == nil {
              rowGridLines = []
            }
            rowGridLines!.append(gridLine)
          }
          uiEventsChunks[uiEventsChunks.count - 1] = .gridLines(
            gridID: chunkGridID,
            hlAttrDefines: hlAttrDefines,
            gridLines: chunkGridLines
          )
        } else {
          uiEventsChunks.append(.gridLines(
            gridID: gridID,
            hlAttrDefines: [],
            gridLines: [row: [gridLine]]
          ))
        }

      case let .hlAttrDefine(id, rgbAttrs, _, _):
        if
          let previousChunk = uiEventsChunks.last,
          case .gridLines(let chunkGridID, var hlAttrDefines, let chunkGridLines) = previousChunk
        {
          hlAttrDefines.append(.init(id: id, rgbAttrs: rgbAttrs))
          uiEventsChunks[uiEventsChunks.count - 1] = .gridLines(
            gridID: chunkGridID,
            hlAttrDefines: hlAttrDefines,
            gridLines: chunkGridLines
          )
        } else {
          uiEventsChunks.append(.single(uiEvent))
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

        case let .hlAttrDefine(id, rgbAttrs, _, _):
          applyHlAttrDefine(id: id, rgbAttrs: rgbAttrs)

        case let .gridResize(gridID, width, height):
          let size = IntegerSize(
            columnsCount: width,
            rowsCount: height
          )
          if state.grids[gridID]?.size != size || state.grids[gridID]?.isDestroyed == true {
            update(&state.grids[gridID]) { [state] grid in
              if grid == nil || grid?.isDestroyed == true {
                let cells = TwoDimensionalArray(size: size, repeatingElement: Cell.default)
                let layout = GridLayout(cells: cells)
                grid = .init(
                  id: gridID,
                  layout: layout,
                  drawRuns: .init(
                    layout: layout,
                    font: state.font,
                    appearance: state.appearance,
                    drawRunCache: state.drawRunCache
                  ),
                  associatedWindow: nil,
                  isHidden: false,
                  isDestroyed: false
                )
              }
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
            apply(update: .resize(size), toGridWithID: gridID)
          }

        case let .gridScroll(gridID, top, bottom, left, right, rowsCount, columnsCount):
          let rectangle = IntegerRectangle(
            origin: .init(column: left, row: top),
            size: .init(columnsCount: right - left, rowsCount: bottom - top)
          )
          let offset = IntegerSize(columnsCount: columnsCount, rowsCount: rowsCount)
          apply(update: .scroll(rectangle: rectangle, offset: offset), toGridWithID: gridID)

        case let .gridClear(gridID):
          apply(update: .clear, toGridWithID: gridID)

        case let .gridDestroy(gridID):
          state.grids[gridID]!.isDestroyed = true
          updates.destroyedGridIDs.insert(gridID)

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
          let origin = IntegerPoint(column: originColumn, row: originRow)
          let size = IntegerSize(columnsCount: columnsCount, rowsCount: rowsCount)

          let zIndex = state.nextWindowZIndex()
          state.grids[gridID]!.associatedWindow = .plain(
            .init(
              id: windowID,
              origin: origin,
              zIndex: zIndex
            )
          )
          state.grids[gridID]!.isHidden = false

          updatedLayout(forGridWithID: gridID)
          if size != state.grids[gridID]!.size {
            apply(update: .resize(size), toGridWithID: gridID)
          }

        case let .winFloatPos(
          gridID,
          windowID,
          rawAnchor,
          anchorGridID,
          anchorRow,
          anchorColumn,
          isFocusable,
          _
        ):
          let anchor = FloatingWindow.Anchor(rawValue: rawAnchor)!

          let zIndex = state.nextWindowZIndex()
          state.grids[gridID]!.associatedWindow = .floating(
            .init(
              id: windowID,
              anchor: anchor,
              anchorGridID: anchorGridID,
              anchorRow: anchorRow,
              anchorColumn: anchorColumn,
              isFocusable: isFocusable,
              zIndex: zIndex
            )
          )
          state.grids[gridID]!.isHidden = false

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

        case .busyStart:
          state.isBusy = true
          isBusyUpdated()

        case .busyStop:
          state.isBusy = false
          isBusyUpdated()

        default:
          break
        }

      case let .gridLines(gridID, hlAttrDefines, gridLines):
        for hlAttrDefine in hlAttrDefines {
          applyHlAttrDefine(id: hlAttrDefine.id, rgbAttrs: hlAttrDefine.rgbAttrs)
        }

        let results: [Grid.LineUpdatesResult] = if gridLines.count < 10 {
          applyLineUpdates(for: gridLines)
        } else {
          await withTaskGroup(of: [Grid.LineUpdatesResult].self) { [state] taskGroup in
            for gridLines in Array(gridLines).chunks(ofCount: 10) {
              taskGroup.addTask {
                var accumulator = [Grid.LineUpdatesResult]()

                for (row, rowGridLines) in gridLines {
                  var lineUpdates = [(originColumn: Int, cells: [Cell])]()

                  for gridLine in rowGridLines {
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

                    lineUpdates.append((gridLine.originColumn, cells))
                  }

                  accumulator.append(
                    state.grids[gridID]!.applying(
                      lineUpdates: lineUpdates,
                      forRow: row,
                      font: state.font,
                      appearance: state.appearance,
                      drawRunCache: state.drawRunCache
                    )
                  )
                }

                return accumulator
              }
            }

            var accumulator = [Grid.LineUpdatesResult]()
            for await results in taskGroup {
              accumulator += results
            }

            return accumulator
          }
        }

        update(&state.grids[gridID]!) { grid in
          for result in results {
            grid.layout.cells.rows[result.row] = result.rowCells
            grid.layout.rowLayouts[result.row] = result.rowLayout
            grid.drawRuns.rowDrawRuns[result.row] = result.rowDrawRun

            if result.shouldUpdateCursorDrawRun {
              grid.drawRuns.cursorDrawRun!.updateParent(
                with: grid.layout,
                rowDrawRuns: grid.drawRuns.rowDrawRuns
              )
            }
          }
        }

        update(&updates.gridUpdates[gridID]) { updates in
          let dirtyRectangles = results.flatMap(\.dirtyRectangles)

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

        func applyLineUpdates(for gridLines: IntKeyedDictionary<[UIEventsChunk.GridLine]>) -> [Grid.LineUpdatesResult] {
          var accumulator = [Grid.LineUpdatesResult]()

          for (row, rowGridLines) in gridLines {
            var lineUpdates = [(originColumn: Int, cells: [Cell])]()

            for gridLine in rowGridLines {
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

              lineUpdates.append((gridLine.originColumn, cells))
            }

            accumulator.append(
              state.grids[gridID]!.applying(
                lineUpdates: lineUpdates,
                forRow: row,
                font: state.font,
                appearance: state.appearance,
                drawRunCache: state.drawRunCache
              )
            )
          }

          return accumulator
        }
      }

      func applyHlAttrDefine(id: Int, rgbAttrs: [Value: Value]) {
        let noCombine = rgbAttrs["noCombine"]
          .flatMap((/Value.boolean).extract(from:)) ?? false

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

        state.appearance.highlights[id] = highlight
      }
    }

    return updates
  }
}
