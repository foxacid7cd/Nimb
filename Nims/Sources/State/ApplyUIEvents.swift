// SPDX-License-Identifier: MIT

import CasePaths
import CustomDump
import IdentifiedCollections
import Library
import MessagePack
import Overture

public extension Actions {
  @PublicInit
  struct ApplyUIEvents: Action {
    public var uiEvents: [UIEvent]

    public func apply(to container: StateContainer) async throws -> State.Updates {
      var updates = State.Updates()

      func modeUpdated() {
        updates.isModeUpdated = true
      }

      func titleUpdated() {
        updates.isTitleUpdated = true
      }

      func appearanceUpdated() {
        if !updates.isAppearanceUpdated {
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

      func messagesUpdated() {
        updates.isMessagesUpdated = true
      }

      func cursorUpdated(oldCursor: Cursor? = nil) {
        if let oldCursor {
          apply(update: .clearCursor, toGridWithID: oldCursor.gridID)
        }
        if container.state.cmdlines.dictionary.isEmpty, let cursor = container.state.cursor, let style = container.state.currentCursorStyle {
          apply(update: .cursor(style: style, position: cursor.position), toGridWithID: cursor.gridID)
        }
        updates.isCursorUpdated = true
      }

      func updatedLayout(forGridWithID gridID: Grid.ID) {
        updates.updatedLayoutGridIDs.insert(gridID)
      }

      func updatedGridsOrder() {
        updates.isGridsOrderUpdated = true
      }

      func apply(update: Grid.Update, toGridWithID gridID: Grid.ID) {
        let font = container.state.font
        let appearance = container.state.appearance

        let result = container.state.grids[gridID]!.apply(
          update: update,
          font: font,
          appearance: appearance
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

      func blockLine(fromRawLine rawLine: Value) throws -> [Cmdline.ContentPart] {
        guard case let .array(rawLine) = rawLine else {
          throw Failure("invalid cmdline raw line value", rawLine)
        }

        var contentParts = [Cmdline.ContentPart]()

        for rawContentPart in rawLine {
          guard
            case let .array(rawContentPart) = rawContentPart,
            rawContentPart.count == 2,
            case let .integer(rawHighlightID) = rawContentPart[0],
            case let .string(text) = rawContentPart[1]
          else {
            throw Failure("invalid cmdline raw content part value", rawContentPart)
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

        case let .hlAttrDefine(id, rgbAttrs, ctermAttrs, rawInfo):
          let hlAttrDefine = try UIEventsChunk.HlAttrDefine(
            id: id,
            rgbAttrs: rgbAttrs,
            ctermAttrs: ctermAttrs,
            rawInfo: rawInfo
          )

          if
            let previousChunk = uiEventsChunks.last,
            case .gridLines(let chunkGridID, var hlAttrDefines, let chunkGridLines) = previousChunk
          {
            hlAttrDefines.append(hlAttrDefine)
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
            container.state.title = title

            titleUpdated()

          case let .modeInfoSet(enabled, cursorStyles):
            container.state.modeInfo = try ModeInfo(
              enabled: enabled,
              cursorStyles: cursorStyles
                .map(CursorStyle.init(raw:))
            )

            cursorUpdated()

          case let .optionSet(name, value):
            container.state.rawOptions.updateValue(
              value,
              forKey: name,
              insertingAt: container.state.rawOptions.count
            )

          case let .modeChange(name, cursorStyleIndex):
            container.state.mode = .init(
              name: name,
              cursorStyleIndex: cursorStyleIndex
            )

            modeUpdated()

            if container.state.cursor != nil {
              cursorUpdated()
            }

          case let .defaultColorsSet(rgbFg, rgbBg, rgbSp, _, _):
            container.state.appearance.defaultForegroundColor = .init(rgb: rgbFg)
            container.state.appearance.defaultBackgroundColor = .init(rgb: rgbBg)
            container.state.appearance.defaultSpecialColor = .init(rgb: rgbSp)
            container.state.flushDrawRuns()

            appearanceUpdated()

          case let .hlAttrDefine(id, rgbAttrs, ctermAttrs, rawInfo):
            try applyHlAttrDefine(.init(id: id, rgbAttrs: rgbAttrs, ctermAttrs: ctermAttrs, rawInfo: rawInfo))

          case let .gridResize(gridID, width, height):
            let size = IntegerSize(
              columnsCount: width,
              rowsCount: height
            )
            if container.state.grids[gridID]?.size != size || container.state.grids[gridID]?.isDestroyed == true {
              let font = container.state.font
              let appearance = container.state.appearance
              update(&container.state.grids[gridID]) { grid in
                if grid == nil || grid?.isDestroyed == true {
                  let cells = TwoDimensionalArray(size: size, repeatingElement: Cell.default)
                  let layout = GridLayout(cells: cells)
                  grid = .init(
                    id: gridID,
                    layout: layout,
                    drawRuns: .init(
                      layout: layout,
                      font: font,
                      appearance: appearance
                    ),
                    associatedWindow: nil,
                    isHidden: false,
                    isDestroyed: false
                  )
                }
              }

              if
                let cursor = container.state.cursor,
                cursor.gridID == gridID,
                cursor.position.column >= size.columnsCount,
                cursor.position.row >= size.rowsCount
              {
                container.state.cursor = nil

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
            container.state.grids[gridID]!.isDestroyed = true
            updates.destroyedGridIDs.insert(gridID)

          case let .gridCursorGoto(gridID, row, column):
            let oldCursor = container.state.cursor

            let cursorPosition = IntegerPoint(
              column: column,
              row: row
            )
            container.state.cursor = .init(
              gridID: gridID,
              position: cursorPosition
            )

            cursorUpdated(oldCursor: oldCursor)

          case let .winPos(gridID, windowID, originRow, originColumn, columnsCount, rowsCount):
            let origin = IntegerPoint(column: originColumn, row: originRow)
            let size = IntegerSize(columnsCount: columnsCount, rowsCount: rowsCount)

            let previousOrderedGridIDs = container.state.orderedGridIDs()

            let zIndex = container.state.nextWindowZIndex()
            container.state.grids[gridID]!.associatedWindow = .plain(
              .init(
                id: windowID,
                origin: origin,
                zIndex: zIndex
              )
            )
            container.state.grids[gridID]!.isHidden = false

            updatedLayout(forGridWithID: gridID)
            if size != container.state.grids[gridID]!.size {
              apply(update: .resize(size), toGridWithID: gridID)
            }

            if previousOrderedGridIDs != container.state.orderedGridIDs() {
              updatedGridsOrder()
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

            let previousOrderedGridIDs = container.state.orderedGridIDs()

            let zIndex = container.state.nextWindowZIndex()
            container.state.grids[gridID]!.associatedWindow = .floating(
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
            container.state.grids[gridID]!.isHidden = false

            updatedLayout(forGridWithID: gridID)

            if previousOrderedGridIDs != container.state.orderedGridIDs() {
              updatedGridsOrder()
            }

          case let .winHide(gridID):
            container.state.grids[gridID]?.isHidden = true

            updatedLayout(forGridWithID: gridID)

          case let .winClose(gridID):
            container.state.grids[gridID]?.associatedWindow = nil

            updatedLayout(forGridWithID: gridID)

          case let .tablineUpdate(currentTabpageID, rawTabpages, currentBufferID, rawBuffers):
            let tabpages = try rawTabpages
              .map { rawTabpage -> Tabpage in
                guard
                  case let .dictionary(rawTabpage) = rawTabpage,
                  let rawID = rawTabpage["tab"]
                    .flatMap({ $0[case: \.ext] }),
                  let name = rawTabpage["name"]
                    .flatMap({ $0[case: \.string] })
                else {
                  throw Failure("invalid tabline raw value", rawTabpage)
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
            if identifiedTabpages != container.state.tabline?.tabpages {
              if identifiedTabpages.count == container.state.tabline?.tabpages.count {
                tablineTabpagesContentUpdated()
              } else {
                tablineTabpagesUpdated()
              }
            }

            let buffers = try rawBuffers
              .map { rawBuffer -> Buffer in
                guard
                  case let .dictionary(rawBuffer) = rawBuffer,
                  let rawID = rawBuffer["buffer"]
                    .flatMap({ $0[case: \.ext] }),
                  let name = rawBuffer["name"]
                    .flatMap({ $0[case: \.string] })
                else {
                  throw Failure("invalid raw buffer value", rawBuffer)
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
            if identifiedBuffers != container.state.tabline?.buffers {
              tablineBuffersUpdated()
            }

            if updates.tabline.isTabpagesUpdated || currentTabpageID != container.state.tabline?.currentTabpageID {
              tablineSelectedTabpageUpdated()
            }

            if updates.tabline.isBuffersUpdated || currentBufferID != container.state.tabline?.currentBufferID {
              tablineSelectedBufferUpdated()
            }

            container.state.tabline = .init(
              currentTabpageID: currentTabpageID,
              tabpages: identifiedTabpages,
              currentBufferID: currentBufferID,
              buffers: identifiedBuffers
            )

          case let .cmdlineShow(content, pos, firstc, prompt, indent, level):
            let oldCursor = container.state.cursor

            let cmdline = try Cmdline(
              contentParts: content
                .map { rawContentPart in
                  guard
                    case let .array(rawContentPart) = rawContentPart,
                    rawContentPart.count == 2,
                    case let .integer(rawHighlightID) = rawContentPart[0],
                    case let .string(text) = rawContentPart[1]
                  else {
                    throw Failure("invalid cmdline raw content part", rawContentPart)
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
            let oldCmdline = container.state.cmdlines.dictionary[level]

            container.state.cmdlines.lastCmdlineLevel = level

            if cmdline != oldCmdline {
              container.state.cmdlines.dictionary[level] = cmdline
              cursorUpdated(oldCursor: oldCursor)
              cmdlinesUpdated()
            }

          case let .cmdlinePos(pos, level):
            let oldCursor = container.state.cursor

            update(&container.state.cmdlines.dictionary[level]) {
              $0?.cursorPosition = pos
            }

            cursorUpdated(oldCursor: oldCursor)
            cmdlinesUpdated()

          case let .cmdlineSpecialChar(c, shift, level):
            update(&container.state.cmdlines.dictionary[level]) {
              $0?.specialCharacter = c
              $0?.shiftAfterSpecialCharacter = shift
            }

            cmdlinesUpdated()

          case let .cmdlineHide(level):
            container.state.cmdlines.dictionary.removeValue(forKey: level)

            cursorUpdated()
            cmdlinesUpdated()

          case let .cmdlineBlockShow(rawLines):
            try container.state.cmdlines.blockLines[container.state.cmdlines.lastCmdlineLevel!] = rawLines
              .map(blockLine(fromRawLine:))

            cmdlinesUpdated()

          case let .cmdlineBlockAppend(rawLine):
            try container.state.cmdlines.blockLines[container.state.cmdlines.lastCmdlineLevel!]!
              .append(blockLine(fromRawLine: .array(rawLine)))

            cmdlinesUpdated()

          case .cmdlineBlockHide:
            container.state.cmdlines.blockLines.removeValue(forKey: container.state.cmdlines.lastCmdlineLevel!)

            cmdlinesUpdated()

          case let .msgShow(rawKind, content, replaceLast):
            if replaceLast, !container.state.msgShows.isEmpty {
              container.state.msgShows.removeLast()
            }

            let kind: MsgShow.Kind
            if let decoded = MsgShow.Kind(rawValue: rawKind) {
              kind = decoded
            } else {
              throw Failure("invalid raw msg_show kind", rawKind)
            }

            if !content.isEmpty {
              try container.state.msgShows.append(.init(
                index: container.state.msgShows.count,
                kind: kind,
                contentParts: content.map(MsgShow.ContentPart.init(raw:))
              ))
            }

            container.state.isMsgShowsDismissed = false
            messagesUpdated()

          case .msgClear:
            container.state.msgShows = []
            messagesUpdated()

          case let .popupmenuShow(rawItems, selected, row, col, gridID):
            let items = try rawItems
              .map(PopupmenuItem.init(raw:))

            let selectedItemIndex: Int? = selected >= 0 ? selected : nil

            let anchor: Popupmenu.Anchor = switch gridID {
            case -1:
              .cmdline(location: col)

            default:
              .grid(id: gridID, origin: .init(column: col, row: row))
            }

            container.state.popupmenu = .init(items: items, selectedItemIndex: selectedItemIndex, anchor: anchor)
            popupmenuUpdated()

          case let .popupmenuSelect(selected):
            if container.state.popupmenu != nil {
              container.state.popupmenu!.selectedItemIndex = selected >= 0 ? selected : nil
              popupmenuSelectionUpdated()
            }

          case .popupmenuHide:
            if container.state.popupmenu != nil {
              container.state.popupmenu = nil
              popupmenuUpdated()
            }

          case .busyStart:
            container.state.isBusy = true
            isBusyUpdated()

          case .busyStop:
            container.state.isBusy = false
            isBusyUpdated()

          case .mouseOn:
            container.state.isMouseOn = true
            updates.isMouseOnUpdated = true

          case .mouseOff:
            container.state.isMouseOn = false
            updates.isMouseOnUpdated = true

          default:
            break
          }

        case let .gridLines(gridID, hlAttrDefines, gridLines):
          for hlAttrDefine in hlAttrDefines {
            try applyHlAttrDefine(hlAttrDefine)
          }

          let grids = container.state.grids
          let font = container.state.font
          let appearance = container.state.appearance

          let results: [Grid.LineUpdatesResult] = if gridLines.count <= 15 {
            try applyLineUpdates(for: gridLines, grids: grids, font: font, appearance: appearance)
          } else {
            try await withThrowingTaskGroup(of: [Grid.LineUpdatesResult].self) { taskGroup in
              let gridLines = Array(gridLines)
              let chunkSize = gridLines.optimalChunkSize(preferredChunkSize: 15)
              for gridLinesChunk in gridLines.chunks(ofCount: chunkSize) {
                taskGroup.addTask {
                  var gridLines = IntKeyedDictionary<[UIEventsChunk.GridLine]>(minimumCapacity: gridLinesChunk.count)
                  for (key, value) in gridLinesChunk {
                    gridLines[key] = value
                  }
                  return try applyLineUpdates(for: gridLines, grids: grids, font: font, appearance: appearance)
                }
              }

              var accumulator = [Grid.LineUpdatesResult]()
              accumulator.reserveCapacity(gridLines.count)
              for try await results in taskGroup {
                accumulator += results
              }

              return accumulator
            }
          }

          update(&container.state.grids[gridID]!) { grid in
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

          @Sendable func applyLineUpdates(
            for gridLines: IntKeyedDictionary<[UIEventsChunk.GridLine]>,
            grids: IntKeyedDictionary<Grid>,
            font: Font,
            appearance: Appearance
          ) throws -> [Grid.LineUpdatesResult] {
            var accumulator = [Grid.LineUpdatesResult]()

            for (row, rowGridLines) in gridLines {
              var lineUpdates = [(originColumn: Int, cells: [Cell])]()

              for gridLine in rowGridLines {
                var cells = [Cell]()
                var highlightID = 0

                for value in gridLine.data {
                  guard
                    case let .array(arrayValue) = value,
                    !arrayValue.isEmpty,
                    case let .string(text) = arrayValue[0]
                  else {
                    throw Failure("invalid grid line cell value", value)
                  }

                  var repeatCount = 1

                  if arrayValue.count > 1 {
                    guard
                      case let .integer(newHighlightID) = arrayValue[1]
                    else {
                      throw Failure("invalid grid line cell highlight value", arrayValue[1])
                    }

                    highlightID = newHighlightID

                    if arrayValue.count > 2 {
                      guard
                        case let .integer(newRepeatCount) = arrayValue[2]
                      else {
                        throw Failure("invalid grid line cell repeat count value", arrayValue[2])
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
                grids[gridID]!.applying(
                  lineUpdates: lineUpdates,
                  forRow: row,
                  font: font,
                  appearance: appearance
                )
              )
            }

            return accumulator
          }
        }

        func applyHlAttrDefine(_ hlAttrDefine: UIEventsChunk.HlAttrDefine) throws {
          let noCombine = hlAttrDefine.rgbAttrs["noCombine"]
            .flatMap { $0[case: \.boolean] } ?? false

          var highlight = (noCombine ? container.state.appearance.highlights[hlAttrDefine.id] : nil) ?? .init(id: hlAttrDefine.id)

          for (key, value) in hlAttrDefine.rgbAttrs {
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
              throw Failure("unknown hl attr define rgb attr key", key)
            }
          }

          container.state.appearance.highlights[hlAttrDefine.id] = highlight

          for infoItem in hlAttrDefine.info {
            guard 
              let rawHiName = infoItem.hiName,
              let hiName = Appearance.ObservedHighlightName(rawValue: rawHiName)
            else {
              continue
            }
            container.state.appearance.observedHighlights[hiName] = (infoItem.id, infoItem.kind)
            updates.updatedObservedHighlightNames.insert(hiName)
          }
        }
      }

      return updates
    }
  }
}
