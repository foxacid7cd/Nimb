// SPDX-License-Identifier: MIT

import CasePaths
import CustomDump
import IdentifiedCollections
import OSLog
import Overture

public extension Actions {
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
        case let .setTitle(batch):
          for params in batch {
            state.title = params.title
          }
          titleUpdated()

        case let .modeInfoSet(batch):
          do {
            for params in batch {
              state.modeInfo = try ModeInfo(
                enabled: params.enabled,
                cursorStyles: params.cursorStyles
                  .map(CursorStyle.init(raw:))
              )
            }
          } catch {
            handleError(error)
          }
          cursorUpdated()

        case let .optionSet(batch):
          for params in batch {
            state.rawOptions.updateValue(
              params.value,
              forKey: params.name,
              insertingAt: state.rawOptions.count
            )
          }
          updates.isRawOptionsUpdated = true

        case let .modeChange(batch):
          for params in batch {
            state.mode = .init(
              name: params.mode,
              cursorStyleIndex: params.modeIDX
            )
          }
          modeUpdated()

          if state.cursor != nil {
            cursorUpdated()
          }

        case let .defaultColorsSet(batch):
          for params in batch {
            state.appearance
              .defaultForegroundColor = .init(rgb: params.rgbFg)
            state.appearance
              .defaultBackgroundColor = .init(rgb: params.rgbBg)
            state.appearance.defaultSpecialColor = .init(rgb: params.rgbSp)
          }
          state.flushDrawRuns()
          appearanceUpdated()

        case let .gridResize(batch):
          for params in batch {
            let size = IntegerSize(
              columnsCount: params.width,
              rowsCount: params.height
            )
            if
              state.grids[params.grid]?.size != size
            {
              let font = state.font
              let appearance = state.appearance
              update(&state.grids[params.grid]) { grid in
                if grid == nil {
                  let cells = TwoDimensionalArray(
                    size: size,
                    repeatingElement: Cell.default
                  )
                  let layout = GridLayout(cells: cells)
                  grid = .init(
                    id: params.grid,
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
                cursor.gridID == params.grid,
                cursor.position.column >= size.columnsCount,
                cursor.position.row >= size.rowsCount
              {
                state.cursor = nil

                cursorUpdated(oldCursor: cursor)
              }

              updatedLayout(forGridWithID: params.grid)
              apply(update: .resize(size), toGridWithID: params.grid)
            }

            let parent = state.gridsHierarchy.allNodes[params.grid]?.parent ?? Grid.OuterID
            state.gridsHierarchy.addNode(id: params.grid, parent: parent)
          }
          updates.isGridsHierarchyUpdated = true

        case let .gridScroll(batch):
          for params in batch {
            let rectangle = IntegerRectangle(
              origin: .init(column: params.left, row: params.top),
              size: .init(columnsCount: params.right - params.left, rowsCount: params.bot - params.top)
            )
            let offset = IntegerSize(
              columnsCount: params.cols,
              rowsCount: params.rows
            )

            apply(
              update: .scroll(rectangle: rectangle, offset: offset),
              toGridWithID: params.grid
            )
          }

        case let .gridClear(batch):
          for params in batch {
            apply(update: .clear, toGridWithID: params.grid)
          }

        case let .gridDestroy(batch):
          for params in batch {
            update(&state.grids[params.grid]) { grid in
              guard grid != nil else {
                return
              }
              grid = nil
              updates.destroyedGridIDs.insert(params.grid)
            }

            state.gridsHierarchy.removeNode(id: params.grid)
          }
          updates.isGridsHierarchyUpdated = true

        case let .gridCursorGoto(batch):
          for params in batch {
            let oldCursor = state.cursor

            let cursorPosition = IntegerPoint(
              column: params.col,
              row: params.row
            )
            state.cursor = .init(
              gridID: params.grid,
              position: cursorPosition
            )

            cursorUpdated(oldCursor: oldCursor)
          }

        case let .winPos(batch):
          for params in batch {
            let origin = IntegerPoint(column: params.startcol, row: params.startrow)
            let size = IntegerSize(
              columnsCount: params.width,
              rowsCount: params.height
            )

            guard
              state
                .grids[params.grid] != nil
            else {
              logger.error("winPos UI event: Grid \(params.grid) doesn't exist or destroyed")
              break
            }

            state.grids[params.grid]?.associatedWindow = .plain(
              .init(
                id: params.windowID,
                origin: origin,
                size: size
              )
            )
            state.grids[params.grid]?.isHidden = false

            state.gridsHierarchy.addNode(id: params.grid, parent: Grid.OuterID)

            updatedLayout(forGridWithID: params.grid)
          }
          updates.isGridsHierarchyUpdated = true

        case let .winFloatPos(batch):
          for params in batch {
            let anchor = FloatingWindow.Anchor(rawValue: params.anchor)!

            guard
              state
                .grids[params.grid] != nil
            else {
              logger.error("winFloatPos UI event: Grid \(params.grid) doesn't exist or destroyed")
              break
            }

            state.grids[params.grid]?.associatedWindow = .floating(
              .init(
                id: params.windowID,
                anchor: anchor,
                anchorGridID: params.anchorGrid,
                anchorRow: params.anchorRow,
                anchorColumn: params.anchorCol,
                isFocusable: params.focusable,
                zIndex: params.zindex
              )
            )
            state.grids[params.grid]?.isHidden = false

            state.gridsHierarchy.addNode(id: params.grid, parent: params.anchorGrid)

            updatedLayout(forGridWithID: params.grid)
          }
          updates.isGridsHierarchyUpdated = true

        case let .winHide(batch):
          for params in batch {
            if state.grids[params.grid] == nil {
              logger.error("winHide UI event: grid \(params.grid) doesn't exist or destroyed")
              break
            }

            state.grids[params.grid]?.isHidden = true

            state.gridsHierarchy.removeNode(id: params.grid)

            updatedLayout(forGridWithID: params.grid)
          }
          updates.isGridsHierarchyUpdated = true

        case let .winClose(batch):
          for params in batch {
            if state.grids[params.grid] == nil {
              logger.error("winClose UI event: Grid \(params.grid) doesn't exist or destroyed")
              break
            }
            state.grids[params.grid]?.associatedWindow = nil

            state.gridsHierarchy.removeNode(id: params.grid)

            updatedLayout(forGridWithID: params.grid)
          }
          updates.isGridsHierarchyUpdated = true

        case let .tablineUpdate(batch):
          for params in batch {
            do {
              let tabpages = try params.tabs
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

              let buffers = try params.buffers
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
                updates.tabline.isTabpagesUpdated || params.tabpageID != state.tabline?.currentTabpageID
              {
                tablineSelectedTabpageUpdated()
              }

              if
                updates.tabline.isBuffersUpdated || params.bufferID != state.tabline?.currentBufferID
              {
                tablineSelectedBufferUpdated()
              }

              state.tabline = .init(
                currentTabpageID: params.tabpageID,
                tabpages: identifiedTabpages,
                currentBufferID: params.bufferID,
                buffers: identifiedBuffers
              )
            } catch {
              handleError(error)
            }
          }

        case let .cmdlineShow(batch):
          for params in batch {
            do {
              let oldCursor = state.cursor

              let cmdline = try Cmdline(
                contentParts: params.content
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
                cursorPosition: params.pos,
                firstCharacter: params.firstc,
                prompt: params.prompt,
                indent: params.indent,
                level: params.level,
                specialCharacter: "",
                shiftAfterSpecialCharacter: false
              )
              let oldCmdline = state.cmdlines.dictionary[params.level]

              state.cmdlines.lastCmdlineLevel = params.level

              if cmdline != oldCmdline {
                state.cmdlines.dictionary[params.level] = cmdline
                cursorUpdated(oldCursor: oldCursor)
                cmdlinesUpdated()
              }
            } catch {
              handleError(error)
            }
          }

        case let .cmdlinePos(batch):
          for params in batch {
            let oldCursor = state.cursor

            update(&state.cmdlines.dictionary[params.level]) {
              $0?.cursorPosition = params.pos
            }

            cursorUpdated(oldCursor: oldCursor)
            cmdlinesUpdated()
          }

        case let .cmdlineSpecialChar(batch):
          for params in batch {
            update(&state.cmdlines.dictionary[params.level]) {
              $0?.specialCharacter = params.c
              $0?.shiftAfterSpecialCharacter = params.shift
            }

            cmdlinesUpdated()
          }

        case let .cmdlineHide(batch):
          for params in batch {
            state.cmdlines.dictionary.removeValue(forKey: params.level)

            cursorUpdated()
            cmdlinesUpdated()
          }

        case let .cmdlineBlockShow(batch):
          for params in batch {
            do {
              try state.cmdlines
                .blockLines[state.cmdlines.lastCmdlineLevel!] = params.lines
                .map(blockLine(fromRawLine:))

              cmdlinesUpdated()
            } catch {
              handleError(error)
            }
          }

        case let .cmdlineBlockAppend(batch):
          for params in batch {
            do {
              try state.cmdlines
                .blockLines[state.cmdlines.lastCmdlineLevel!]?
                .append(blockLine(fromRawLine: .array(params.lines)))

              cmdlinesUpdated()
            } catch {
              handleError(error)
            }
          }

        case .cmdlineBlockHide:
          state.cmdlines.blockLines
            .removeValue(forKey: state.cmdlines.lastCmdlineLevel!)

          cmdlinesUpdated()

        case let .msgShow(batch):
          for params in batch {
            do {
              if params.replaceLast {
                state.msgShows.removeLast()
              }

              let kind: MsgShow.Kind
              if let decoded = MsgShow.Kind(rawValue: params.kind) {
                kind = decoded
              } else {
                throw Failure("invalid raw msg_show kind", params.kind)
              }

              if !params.content.isEmpty {
                try state.msgShows.append(.init(
                  index: state.msgShows.count,
                  kind: kind,
                  contentParts: params.content.map(MsgShow.ContentPart.init(raw:))
                ))
                if params.replaceLast {
                  updates.msgShowsUpdates
                    .append(.reload(indexes: [state.msgShows.count - 1]))
                } else {
                  updates.msgShowsUpdates.append(.added(count: 1))
                }
              } else if params.replaceLast {
                throw Failure("replaceLast with empty content inconsistency")
              }
            } catch {
              handleError(error)
            }
          }

        case .msgClear:
          state.msgShows = []
          updates.msgShowsUpdates.append(.clear)

        case let .popupmenuShow(batch):
          for params in batch {
            do {
              let items = try params.items
                .map(PopupmenuItem.init(raw:))

              let selectedItemIndex: Int? = params.selected >= 0 ? params.selected : nil

              let anchor: Popupmenu.Anchor =
                switch params.grid {
                case -1:
                  .cmdline(location: params.col)

                default:
                  .grid(id: params.grid, origin: .init(column: params.col, row: params.row))
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
          }

        case let .popupmenuSelect(batch):
          for params in batch {
            if state.popupmenu != nil {
              state.popupmenu!
                .selectedItemIndex = params.selected >= 0 ? params.selected : nil
              popupmenuSelectionUpdated()
            }
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

        case let .hlAttrDefine(batch):
          for params in batch {
            let noCombine = params.rgbAttrs["noCombine"]
              .flatMap { $0[case: \.boolean] } ?? false

            var highlight = (
              noCombine ? state.appearance
                .highlights[params.id] : nil
            ) ?? .init(id: params.id)

            for (key, value) in params.rgbAttrs {
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

            state.appearance.highlights[params.id] = highlight

            for rawInfoItem in params.info {
              if
                case let .dictionary(dict) = rawInfoItem,
                case let .string(hiName) = dict["hi_name"],
                let observedHighlightName = Appearance.ObservedHighlightName(
                  rawValue: hiName
                )
              {
                state.appearance
                  .observedHighlights[observedHighlightName] = (
                    dict["id"].flatMap(\.integer),
                    dict["kind"].flatMap(\.string)
                  )
                updates.updatedObservedHighlightNames
                  .insert(observedHighlightName)
              }
            }
          }

        case let .gridLine(batch):
          for params in batch {
            let gridID = params.grid
            let row = params.row
            let colStart = params.colStart
            let data = params.data

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
