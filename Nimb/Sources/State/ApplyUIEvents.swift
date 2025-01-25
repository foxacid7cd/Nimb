// SPDX-License-Identifier: MIT

import CasePaths
import CustomDump
import IdentifiedCollections
import OSLog
import Overture

public extension Actions {
  @PublicInit
  struct ApplyUIEvents<S: Sequence>: Action where S.Element == UIEvent,
    S: Sendable
  {
    public var uiEvents: S

    public func apply(to state: inout State, handleError: @Sendable (Error) -> Void) -> State.Updates {
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

      func cursorUpdated(oldCursor: Cursor? = nil) {
        if let oldCursor {
          apply(update: .clearCursor, toGridWithID: oldCursor.gridID)
        }
        if
          state.cmdlines.dictionary.isEmpty,
          let cursor = state.cursor,
          let style = state.currentCursorStyle
        {
          apply(
            update: .cursor(style: style, position: cursor.position),
            toGridWithID: cursor.gridID
          )
        }
        updates.isCursorUpdated = true
      }

      func updatedLayout(forGridWithID gridID: Grid.ID) {
        updates.updatedLayoutGridIDs.insert(gridID)
      }

      func apply(update: Grid.Update, toGridWithID gridID: Grid.ID) {
        let font = state.font
        let appearance = state.appearance
        let outerGrid = state.outerGrid
        Overture.update(&state.grids[gridID]) { grid in
          if grid == nil {
            grid = Grid(
              id: gridID,
              size: outerGrid!.size,
              font: font,
              appearance: appearance
            )
            grid!.isHidden = true
          }
        }
        let result = state.grids[gridID]!.apply(
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

      func blockLine(fromRawLine rawLine: Value) throws
        -> [Cmdline.ContentPart]
      {
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
            throw Failure(
              "invalid cmdline raw content part value",
              rawContentPart
            )
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

      var isLastFlushEvent = false

      for uiEvent in uiEvents {
        switch uiEvent {
        case let .setTitle(title):
          state.title = title
          titleUpdated()

        case let .modeInfoSet(enabled, cursorStyles):
          do {
            state.modeInfo = try ModeInfo(
              enabled: enabled,
              cursorStyles: cursorStyles
                .map(CursorStyle.init(raw:))
            )
            cursorUpdated()
          } catch {
            handleError(error)
          }

        case let .optionSet(name, value):
          state.rawOptions.updateValue(
            value,
            forKey: name,
            insertingAt: state.rawOptions.count
          )
          updates.isRawOptionsUpdated = true

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
          state.appearance
            .defaultForegroundColor = .init(rgb: rgbFg)
          state.appearance
            .defaultBackgroundColor = .init(rgb: rgbBg)
          state.appearance.defaultSpecialColor = .init(rgb: rgbSp)
          state.flushDrawRuns()

          appearanceUpdated()

        case let .gridResize(gridID, width, height):
          let size = IntegerSize(
            columnsCount: width,
            rowsCount: height
          )
          if
            state.grids[gridID]?.size != size
          {
            let font = state.font
            let appearance = state.appearance
            update(&state.grids[gridID]) { grid in
              if grid == nil {
                let cells = TwoDimensionalArray(
                  size: size,
                  repeatingElement: Cell.default
                )
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
                  isHidden: false
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

            state.gridsHierarchy.addNode(id: gridID, parent: Grid.OuterID)
            updates.isGridsHierarchyUpdated = true

            updatedLayout(forGridWithID: gridID)
            apply(update: .resize(size), toGridWithID: gridID)
          }

        case let .gridScroll(
          gridID,
          top,
          bottom,
          left,
          right,
          rowsCount,
          columnsCount
        ):
          let rectangle = IntegerRectangle(
            origin: .init(column: left, row: top),
            size: .init(columnsCount: right - left, rowsCount: bottom - top)
          )
          let offset = IntegerSize(
            columnsCount: columnsCount,
            rowsCount: rowsCount
          )

          apply(
            update: .scroll(rectangle: rectangle, offset: offset),
            toGridWithID: gridID
          )

        case let .gridClear(gridID):
          apply(update: .clear, toGridWithID: gridID)

        case let .gridDestroy(gridID):
          update(&state.grids[gridID]) { grid in
            guard grid != nil else {
              return
            }
            grid = nil
            updates.destroyedGridIDs.insert(gridID)
          }

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

        case let .winPos(
          gridID,
          windowID,
          originRow,
          originColumn,
          columnsCount,
          rowsCount
        ):
          let origin = IntegerPoint(column: originColumn, row: originRow)
          let size = IntegerSize(
            columnsCount: columnsCount,
            rowsCount: rowsCount
          )

          guard
            state
              .grids[gridID] != nil
          else {
            logger.error("winPos UI event: Grid \(gridID) doesn't exist or destroyed")
            break
          }

          state.grids[gridID]?.associatedWindow = .plain(
            .init(
              id: windowID,
              origin: origin,
              size: size
            )
          )
          state.grids[gridID]?.isHidden = false

          state.gridsHierarchy.addNode(id: gridID, parent: Grid.OuterID)
          updates.isGridsHierarchyUpdated = true

          updatedLayout(forGridWithID: gridID)

        case let .winFloatPos(
          gridID,
          windowID,
          rawAnchor,
          anchorGridID,
          anchorRow,
          anchorColumn,
          isFocusable,
          zIndex
        ):
          let anchor = FloatingWindow.Anchor(rawValue: rawAnchor)!

          guard
            state
              .grids[gridID] != nil
          else {
            logger.error("winFloatPos UI event: Grid \(gridID) doesn't exist or destroyed")
            break
          }

          state.grids[gridID]?.associatedWindow = .floating(
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
          state.grids[gridID]?.isHidden = false

          state.gridsHierarchy.addNode(id: gridID, parent: anchorGridID)
          updates.isGridsHierarchyUpdated = true

          updatedLayout(forGridWithID: gridID)

        case let .winHide(gridID):
          if state.grids[gridID] == nil {
            logger.error("winHide UI event: grid \(gridID) doesn't exist or destroyed")
            break
          }

          state.grids[gridID]?.isHidden = true

          updatedLayout(forGridWithID: gridID)

        case let .winClose(gridID):
          if state.grids[gridID] == nil {
            logger.error("winClose UI event: Grid \(gridID) doesn't exist or destroyed")
            break
          }
          state.grids[gridID]?.associatedWindow = nil

          state.gridsHierarchy.removeNode(id: gridID)
          updates.isGridsHierarchyUpdated = false

          updatedLayout(forGridWithID: gridID)

        case let .tablineUpdate(
          currentTabpageID,
          rawTabpages,
          currentBufferID,
          rawBuffers
        ):
          do {
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
            if identifiedTabpages != state.tabline?.tabpages {
              if
                identifiedTabpages.count == state.tabline?.tabpages
                  .count
              {
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
            if identifiedBuffers != state.tabline?.buffers {
              tablineBuffersUpdated()
            }

            if
              updates.tabline.isTabpagesUpdated || currentTabpageID != state.tabline?.currentTabpageID
            {
              tablineSelectedTabpageUpdated()
            }

            if
              updates.tabline.isBuffersUpdated || currentBufferID != state.tabline?.currentBufferID
            {
              tablineSelectedBufferUpdated()
            }

            state.tabline = .init(
              currentTabpageID: currentTabpageID,
              tabpages: identifiedTabpages,
              currentBufferID: currentBufferID,
              buffers: identifiedBuffers
            )
          } catch {
            handleError(error)
          }

        case let .cmdlineShow(content, pos, firstc, prompt, indent, level):
          do {
            let oldCursor = state.cursor

            let cmdline = try Cmdline(
              contentParts: content
                .map { rawContentPart in
                  guard
                    case let .array(rawContentPart) = rawContentPart,
                    rawContentPart.count == 2,
                    case let .integer(rawHighlightID) = rawContentPart[0],
                    case let .string(text) = rawContentPart[1]
                  else {
                    throw Failure(
                      "invalid cmdline raw content part",
                      rawContentPart
                    )
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
          } catch {
            handleError(error)
          }

        case let .cmdlinePos(pos, level):
          let oldCursor = state.cursor

          update(&state.cmdlines.dictionary[level]) {
            $0?.cursorPosition = pos
          }

          cursorUpdated(oldCursor: oldCursor)
          cmdlinesUpdated()

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
          do {
            try state.cmdlines
              .blockLines[state.cmdlines.lastCmdlineLevel!] = rawLines
              .map(blockLine(fromRawLine:))

            cmdlinesUpdated()
          } catch {
            handleError(error)
          }

        case let .cmdlineBlockAppend(rawLine):
          do {
            try state.cmdlines
              .blockLines[state.cmdlines.lastCmdlineLevel!]?
              .append(blockLine(fromRawLine: .array(rawLine)))

            cmdlinesUpdated()
          } catch {
            handleError(error)
          }

        case .cmdlineBlockHide:
          state.cmdlines.blockLines
            .removeValue(forKey: state.cmdlines.lastCmdlineLevel!)

          cmdlinesUpdated()

        case let .msgShow(rawKind, content, replaceLast):
          do {
            if replaceLast {
              state.msgShows.removeLast()
            }

            let kind: MsgShow.Kind
            if let decoded = MsgShow.Kind(rawValue: rawKind) {
              kind = decoded
            } else {
              throw Failure("invalid raw msg_show kind", rawKind)
            }

            if !content.isEmpty {
              try state.msgShows.append(.init(
                index: state.msgShows.count,
                kind: kind,
                contentParts: content.map(MsgShow.ContentPart.init(raw:))
              ))
              if replaceLast {
                updates.msgShowsUpdates
                  .append(.reload(indexes: [state.msgShows.count - 1]))
              } else {
                updates.msgShowsUpdates.append(.added(count: 1))
              }
            } else if replaceLast {
              throw Failure("replaceLast with empty content inconsistency")
            }
          } catch {
            handleError(error)
          }

        case .msgClear:
          state.msgShows = []
          updates.msgShowsUpdates.append(.clear)

        case let .popupmenuShow(rawItems, selected, row, col, gridID):
          do {
            let items = try rawItems
              .map(PopupmenuItem.init(raw:))

            let selectedItemIndex: Int? = selected >= 0 ? selected : nil

            let anchor: Popupmenu.Anchor =
              switch gridID {
              case -1:
                .cmdline(location: col)

              default:
                .grid(id: gridID, origin: .init(column: col, row: row))
              }

            state.popupmenu = .init(
              items: items,
              selectedItemIndex: selectedItemIndex,
              anchor: anchor
            )
            popupmenuUpdated()
          } catch {
            handleError(error)
          }

        case let .popupmenuSelect(selected):
          if state.popupmenu != nil {
            state.popupmenu!
              .selectedItemIndex = selected >= 0 ? selected : nil
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

        case .mouseOn:
          state.isMouseOn = true
          updates.isMouseOnUpdated = true

        case .mouseOff:
          state.isMouseOn = false
          updates.isMouseOnUpdated = true

        case let .hlAttrDefine(id, rgbAttrs, _, info):
          let noCombine = rgbAttrs["noCombine"]
            .flatMap { $0[case: \.boolean] } ?? false

          var highlight = (
            noCombine ? state.appearance
              .highlights[id] : nil
          ) ?? .init(id: id)

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
                 "standout",
                 "url":
              continue

            default:
              handleError(Failure("Unknown hl attr define rgb attr key", key))
            }
          }

          state.appearance.highlights[id] = highlight

          for rawInfoItem in info {
            guard
              case let .dictionary(dict) = rawInfoItem,
              case let .string(kind) = dict["kind"],
              case let .integer(infoID) = dict["id"],
              case let .string(hiName) = dict["hi_name"]
            else {
              handleError(Failure("invalid hl attr define info item", rawInfoItem))
              continue
            }

            if
              let observedHighlightName = Appearance.ObservedHighlightName(
                rawValue: hiName
              )
            {
              state.appearance.observedHighlights[observedHighlightName] = (infoID, kind)
              updates.updatedObservedHighlightNames
                .insert(observedHighlightName)
            }
          }

        case let .gridLine(gridID, row, colStart, data, _):
          var cells = [Cell]()
          var highlightID = 0

          for value in data {
            guard
              case let .array(arrayValue) = value,
              !arrayValue.isEmpty,
              case let .string(text) = arrayValue[0]
            else {
              handleError(Failure("invalid grid line cell value", value))
              break
            }

            var repeatCount = 1

            if arrayValue.count > 1 {
              guard
                case let .integer(newHighlightID) = arrayValue[1]
              else {
                handleError(Failure(
                  "invalid grid line cell highlight value",
                  arrayValue[1]
                ))
                break
              }

              highlightID = newHighlightID

              if arrayValue.count > 2 {
                guard
                  case let .integer(newRepeatCount) = arrayValue[2]
                else {
                  handleError(Failure(
                    "invalid grid line cell repeat count value",
                    arrayValue[2]
                  ))
                  break
                }

                repeatCount = newRepeatCount
              }
            }

            if text.count > 1 {
              handleError(Failure("grid line cell text has more than one character", text))
            } else if text.isEmpty, !cells.isEmpty {
              cells[cells.count - 1].isDoubleWidth = true
            }

            let cell = Cell(
              character: text.first ?? Cell.default.character,
              isDoubleWidth: false,
              highlightID: highlightID
            )
            for _ in 0 ..< repeatCount {
              cells.append(cell)
            }
          }

          let dirtyRectangle = state
            .grids[gridID]!
            .applyLineUpdate(
              originColumn: colStart,
              cells: cells,
              row: row,
              font: state.font,
              appearance: state.appearance
            )

          update(&updates.gridUpdates[gridID]) { updates in
            switch updates {
            case var .dirtyRectangles(accumulator):
              accumulator.append(dirtyRectangle)
              updates = .dirtyRectangles(accumulator)

            case .none:
              updates = .dirtyRectangles([dirtyRectangle])

            default:
              break
            }
          }

        default:
          break
        }

        if case .flush = uiEvent {
          isLastFlushEvent = true
        } else {
          isLastFlushEvent = false
        }
      }

      updates.needFlush = isLastFlushEvent

      return updates
    }
  }
}
