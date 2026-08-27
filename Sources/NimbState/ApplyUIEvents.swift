// SPDX-License-Identifier: MIT

import NimbCore
import NimbNeovim
import OSLog

public extension Actions {
  @PublicInit
  struct ApplyUIEvents<S: Sequence & Sendable>: Action where S.Element == UIEvent {
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
            toGridWithID: cursor.gridID,
          )
        }
        updates.isCursorUpdated = true
      }

      func updatedLayout(forGridWithID gridID: Grid.ID) {
        updates.updatedLayoutGridIDs.insert(gridID)
      }

      func mergeGridUpdate(_ gridUpdate: Grid.UpdateResult, forGridWithID gridID: Grid.ID) {
        if let existingUpdate = updates.gridUpdates[gridID] {
          var mergedUpdate = existingUpdate
          mergedUpdate.formUnion(gridUpdate)
          updates.gridUpdates[gridID] = mergedUpdate
        } else {
          updates.gridUpdates[gridID] = gridUpdate
        }
      }

      func apply(update: Grid.Update, toGridWithID gridID: Grid.ID) {
        let font = state.font
        let appearance = state.appearance
        if state.grids[gridID] == nil {
          // Read inline rather than hoisted above the branch: binding the
          // outer grid to a local keeps a second reference to its cells alive
          // for the rest of this function, which is exactly what makes the
          // mutation below copy.
          var grid = Grid(
            id: gridID,
            size: state.outerGrid!.size,
            font: font,
            appearance: appearance,
          )
          grid.isHidden = true
          state.grids[gridID] = grid
        }

        // Mutated in place through the dictionary's _modify accessor. Copying
        // the grid into a local, mutating it and assigning it back leaves the
        // dictionary holding the original, so the first write inside `apply`
        // copies the whole cell buffer and the write-back then releases it.
        let result = state.grids[gridID]!.apply(
          update: update,
          font: font,
          appearance: appearance,
        )

        if let result {
          mergeGridUpdate(result, forGridWithID: gridID)
        }
      }

      func reindexMsgShows() {
        for index in state.msgShows.indices {
          state.msgShows[index].index = index
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
          // [attrs, text, hl_id] — the highlight is the third element. It
          // used to be a two element [attr_id, text].
          guard
            case let .array(rawContentPart) = rawContentPart,
            rawContentPart.count == 3,
            case let .string(text) = rawContentPart[1],
            case let .integer(rawHighlightID) = rawContentPart[2]
          else {
            throw Failure(
              "invalid cmdline raw content part value",
              rawContentPart,
            )
          }

          contentParts.append(
            .init(
              highlightID: .init(rawHighlightID),
              text: text,
            ),
          )
        }

        return contentParts
      }

      var lastUIEvent: UIEvent?

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
                  .map(CursorStyle.init(raw:)),
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
              insertingAt: state.rawOptions.count,
            )
          }
          updates.isRawOptionsUpdated = true

        case let .modeChange(batch):
          for params in batch {
            state.mode = .init(
              name: params.mode,
              cursorStyleIndex: params.modeIDX,
            )
          }
          modeUpdated()

          if state.cursor != nil {
            cursorUpdated()
          }

        case let .defaultColorsSet(batch):
          // Acted on only when the colours actually differ.
          //
          // Neovim re-emits default_colors_set as part of ordinary redraw
          // cycles, carrying the same values it sent last time, and this used
          // to take every one of them at face value: flushDrawRuns reshapes
          // every row of every grid from scratch, and isAppearanceUpdated
          // makes every grid rebuild its scene while the tabline, the message
          // list, the cmdlines and the popupmenu all reconstruct their views.
          // Counting the flag showed it set on half of all frames during a
          // workload that never changed a colour.
          var didChangeDefaultColors = false
          for params in batch {
            let foregroundColor = Color(rgb: params.rgbFg)
            let backgroundColor = Color(rgb: params.rgbBg)
            let specialColor = Color(rgb: params.rgbSp)

            guard
              foregroundColor != state.appearance.defaultForegroundColor
              || backgroundColor != state.appearance.defaultBackgroundColor
              || specialColor != state.appearance.defaultSpecialColor
            else {
              continue
            }

            state.appearance.defaultForegroundColor = foregroundColor
            state.appearance.defaultBackgroundColor = backgroundColor
            state.appearance.defaultSpecialColor = specialColor
            didChangeDefaultColors = true
          }

          if didChangeDefaultColors {
            state.flushDrawRuns()
            appearanceUpdated()
          }

        case let .gridResize(batch):
          for params in batch {
            if state.debug.isStoreActionsLoggingEnabled {
              logger.trace("UIEvent.gridResize: grid: \(params.grid)")
            }

            let size = IntegerSize(
              columnsCount: params.width,
              rowsCount: params.height,
            )
            if
              state.grids[params.grid]?.size != size
            {
              let font = state.font
              let appearance = state.appearance
              if state.grids[params.grid] == nil {
                let cells = TwoDimensionalArray(
                  size: size,
                  repeatingElement: Cell.whitespace,
                )
                let layout = GridLayout(cells: cells)
                state.grids[params.grid] = .init(
                  id: params.grid,
                  layout: layout,
                  drawRuns: .init(
                    layout: layout,
                    font: font,
                    appearance: appearance,
                  ),
                  associatedWindow: nil,
                  isHidden: false,
                )
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
              size: .init(columnsCount: params.right - params.left, rowsCount: params.bot - params.top),
            )
            let offset = IntegerSize(
              columnsCount: params.cols,
              rowsCount: params.rows,
            )

            apply(
              update: .scroll(rectangle: rectangle, offset: offset),
              toGridWithID: params.grid,
            )
          }

        case let .gridClear(batch):
          for params in batch {
            apply(update: .clear, toGridWithID: params.grid)
          }

        case let .gridDestroy(batch):
          for params in batch {
            if state.grids.removeValue(forKey: params.grid) != nil {
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
              row: params.row,
            )
            state.cursor = .init(
              gridID: params.grid,
              position: cursorPosition,
            )

            cursorUpdated(oldCursor: oldCursor)
          }

        case let .winPos(batch):
          for params in batch {
            if state.debug.isStoreActionsLoggingEnabled {
              logger.trace("UIEvent.winPos: grid: \(params.grid)")
            }

            let origin = IntegerPoint(column: params.startcol, row: params.startrow)
            let size = IntegerSize(
              columnsCount: params.width,
              rowsCount: params.height,
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
                size: size,
              ),
            )
            state.grids[params.grid]?.isHidden = false

            state.gridsHierarchy.addNode(id: params.grid, parent: Grid.OuterID)

            updatedLayout(forGridWithID: params.grid)
          }
          updates.isGridsHierarchyUpdated = true

        case let .winFloatPos(batch):
          for params in batch {
            if state.debug.isStoreActionsLoggingEnabled {
              logger.trace("UIEvent.winFloatPos: grid: \(params.grid), anchorGrid: \(params.anchorGrid)")
            }

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
                anchorGridID: params.anchorGrid,
                screenRow: params.screenRow,
                screenColumn: params.screenCol,
                isFocusable: params.mouseEnabled,
                zIndex: params.zindex,
                compositingIndex: params.compindex,
              ),
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
                      .flatMap(\.ext),
                      let name = rawTabpage["name"]
                        .flatMap(\.string)
                  else {
                    throw Failure("invalid tabline raw value", rawTabpage)
                  }

                  return .init(
                    id: .init(
                      type: rawID.0,
                      data: rawID.1,
                    )!,
                    name: name,
                  )
                }
              if tabpages != state.tabline?.tabpages {
                if
                  tabpages.count == state.tabline?.tabpages
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
                      .flatMap(\.ext),
                      let name = rawBuffer["name"]
                        .flatMap(\.string)
                  else {
                    throw Failure("invalid raw buffer value", rawBuffer)
                  }

                  return .init(
                    id: .init(
                      type: rawID.0,
                      data: rawID.1,
                    )!,
                    name: name,
                  )
                }
              if buffers != state.tabline?.buffers {
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
                tabpages: tabpages,
                currentBufferID: params.bufferID,
                buffers: buffers,
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
                    // [attrs, text, hl_id], as in cmdline_block_show.
                    guard
                      case let .array(rawContentPart) = rawContentPart,
                      rawContentPart.count == 3,
                      case let .string(text) = rawContentPart[1],
                      case let .integer(rawHighlightID) = rawContentPart[2]
                    else {
                      throw Failure(
                        "invalid cmdline raw content part",
                        rawContentPart,
                      )
                    }

                    return .init(
                      highlightID: .init(rawHighlightID),
                      text: text,
                    )
                  },
                cursorPosition: params.pos,
                firstCharacter: params.firstc,
                prompt: params.prompt,
                promptHighlightID: .init(params.hlID),
                indent: params.indent,
                level: params.level,
                specialCharacter: "",
                shiftAfterSpecialCharacter: false,
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

            state.cmdlines.dictionary[params.level]?.cursorPosition = params.pos

            cursorUpdated(oldCursor: oldCursor)
            cmdlinesUpdated()
          }

        case let .cmdlineSpecialChar(batch):
          for params in batch {
            if var cmdline = state.cmdlines.dictionary[params.level] {
              cmdline.specialCharacter = params.c
              cmdline.shiftAfterSpecialCharacter = params.shift
              state.cmdlines.dictionary[params.level] = cmdline
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

        case .flush:
          // Ends the current message batch, so the next msg_show starts a
          // fresh message area.
          state.hasMsgShowSinceFlush = false

        case let .msgShow(batch):
          for params in batch {
            // The first message of a batch replaces whatever the last batch
            // left on screen. `:echon` is the exception: it continues the
            // previous message, so that message has to survive.
            if !state.hasMsgShowSinceFlush {
              state.hasMsgShowSinceFlush = true

              if !params.append, !state.msgShows.isEmpty {
                state.msgShows = []
                updates.msgShowsUpdates.append(.clear)
              }
            }

            do {
              // Unknown kinds are treated as `unknown`; the API contract says
              // new ones may be added at any time.
              let kind = MsgShow.Kind(rawValue: params.kind) ?? .unknown
              let contentParts = try params.content
                .map(MsgShow.ContentPart.init(raw:))
              let messageID: Value? = params.id.isNil ? nil : params.id

              // `append` is :echon — the message continues the previous one
              // inline rather than starting a new line.
              if params.append, let lastIndex = state.msgShows.indices.last {
                state.msgShows[lastIndex].contentParts += contentParts
                updates.msgShowsUpdates.append(.reload(indexes: [lastIndex]))
                continue
              }

              guard !contentParts.isEmpty else {
                // Nothing to add. `:echo ""` arrives here as the `empty` kind
                // with replaceLast false, and means the message area should
                // come down -- which the batch clear above has already done,
                // so long as this message was the only one in its batch, which
                // is exactly the condition Neovim documents for it.
                //
                // Empty content that does replace the previous message is
                // Neovim taking that one message back down.
                if params.replaceLast, !state.msgShows.isEmpty {
                  state.msgShows.removeLast()
                  reindexMsgShows()
                  // Two updates, because removal shifts every later index and
                  // the incremental reload path cannot express that. The view
                  // rebuilds when it sees more than one update.
                  updates.msgShowsUpdates.append(.clear)
                  updates.msgShowsUpdates
                    .append(.added(count: state.msgShows.count))
                }
                continue
              }

              // A visible message carrying the same id is replaced in place.
              if
                let messageID,
                let index = state.msgShows
                  .firstIndex(where: { $0.messageID == messageID })
              {
                state.msgShows[index].kind = kind
                state.msgShows[index].contentParts = contentParts
                updates.msgShowsUpdates.append(.reload(indexes: [index]))
                continue
              }

              // Only a replacement that found something to replace reloads a
              // row. replaceLast with nothing on screen is an addition, and
              // reporting it as a reload pointed the view at a row it did not
              // have yet.
              let didReplaceLast = params.replaceLast && !state.msgShows.isEmpty
              if didReplaceLast {
                state.msgShows.removeLast()
              }

              state.msgShows.append(.init(
                index: state.msgShows.count,
                kind: kind,
                contentParts: contentParts,
                messageID: messageID,
              ))

              if didReplaceLast {
                updates.msgShowsUpdates
                  .append(.reload(indexes: [state.msgShows.count - 1]))
              } else {
                updates.msgShowsUpdates.append(.added(count: 1))
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
                anchor: anchor,
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
              .flatMap(\.boolean) ?? false

            var highlight = (
              noCombine ? state.appearance
                .highlights[params.id] : nil,
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
            updates.isHighlightsUpdated = true

            for rawInfoItem in params.info {
              if
                case let .dictionary(dict) = rawInfoItem,
                case let .string(hiName) = dict["hi_name"],
                let observedHighlightName = Appearance.ObservedHighlightName(
                  rawValue: hiName,
                )
              {
                state.appearance
                  .observedHighlights[observedHighlightName] = (
                    dict["id"].flatMap(\.integer),
                    dict["kind"].flatMap(\.string),
                  )
                updates.updatedObservedHighlightNames
                  .insert(observedHighlightName)
              }
            }
          }

        case let .gridLine(batch):
          for params in batch {
            if state.debug.isStoreActionsLoggingEnabled {
              logger.trace("UIEvent.gridLine: grid: \(params.grid), row: \(params.row), colStart: \(params.colStart)")
            }

            let gridID = params.grid
            let row = params.row
            let colStart = params.colStart
            let data = params.data

            // Only the column count is read out. Binding the grid itself to a
            // local, as this used to, holds a second reference to its cells
            // for as long as the local lives, which turns the row replacement
            // below into a copy of the entire buffer plus a release of the
            // old one -- together the single most expensive thing the reducer
            // did while scrolling.
            guard let columnsCount = state.grids[gridID]?.columnsCount else {
              handleError(Failure("grid line event: Grid doesn't exist or destroyed", gridID))
              break
            }

            var cells = [Cell]()
            let remainingColumns = columnsCount - colStart
            cells.reserveCapacity(max(data.runs.count, remainingColumns))
            var highlightID = 0

            // The runs arrive already decoded -- the shape checking that used
            // to happen here now happens once, off the msgpack objects, so
            // this is only the expansion into cells.
            for run in data.runs {
              if let runHighlightID = run.highlightID {
                highlightID = runHighlightID
              }

              if run.text.count > 1 {
                handleError(
                  Failure("grid line cell text has more than one character", run.text),
                )
              } else if run.text.isEmpty, !cells.isEmpty {
                cells[cells.count - 1].isDoubleWidth = true
              }

              let cell = Cell(
                character: run.text.first,
                isDoubleWidth: false,
                highlightID: highlightID,
              )
              for _ in 0 ..< (run.repeatCount ?? 1) {
                cells.append(cell)
              }
            }

            // Hoisted so neither is read from `state` while the grid slot is
            // being mutated through it.
            let font = state.font
            let appearance = state.appearance

            let dirtyRectangle = state.grids[gridID]!
              .applyLineUpdate(
                originColumn: colStart,
                cells: cells,
                row: row,
                font: font,
                appearance: appearance,
              )

            mergeGridUpdate(.dirtyRectangles([dirtyRectangle]), forGridWithID: gridID)
          }

        case let .errorExit(batch):
          for params in batch {
            state.errorExitStatus = params.status
          }
          updates.isErrorExitStatusUpdated = true

        default:
          break
        }

        lastUIEvent = uiEvent
      }

      updates.isFromRedrawBatch = true

      if case .flush = lastUIEvent {
        updates.needFlush = true
      }

      return updates
    }
  }
}
