// SPDX-License-Identifier: MIT

import AppKit
import AsyncAlgorithms
import CasePaths
import ComposableArchitecture
import IdentifiedCollections
import Library
import MessagePack
import Neovim
import Overture
import Tagged

public struct Instance: ReducerProtocol {
  public init() {}

  public enum Action {
    case setDefaultFont(Font)
    case createNeovimProcess(
      arguments: [String],
      environmentOverlay: [String: String],
      keyPresses: AsyncStream<KeyPress>,
      mouseEvents: AsyncStream<MouseEvent>,
      tabSelections: AsyncStream<References.Tabpage>
    )
    case bindNeovimProcess(
      Neovim.Process,
      keyPresses: AsyncStream<KeyPress>,
      mouseEvents: AsyncStream<MouseEvent>,
      tabSelections: AsyncStream<References.Tabpage>
    )
    case applyUIEventsBatch([UIEvent])
    case runCursorBlinking
    case setCursorBlinkingPhase(Bool)
    case handleError(Error)
    case processFinished(error: Error?)
  }

  public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case let .setDefaultFont(font):
      state.defaultFont = font

      return .none

    case let .createNeovimProcess(arguments, environmentOverlay, keyPresses, mouseEvents, tabSelections):
      let process = Neovim.Process(
        arguments: arguments,
        environmentOverlay: environmentOverlay
      )

      return .run { send in
        do {
          for try await state in await process.states {
            switch state {
            case .running:
              await send(
                .bindNeovimProcess(
                  process,
                  keyPresses: keyPresses,
                  mouseEvents: mouseEvents,
                  tabSelections: tabSelections
                )
              )
            }
          }

          await send(.processFinished(error: nil))

        } catch {
          await send(.processFinished(error: error))
        }
      }
      .concatenate(with: .cancel(id: EffectID.bindProcess))

    case let .bindNeovimProcess(process, keyPresses, mouseEvents, tabSelections):
      let applyUIEventBatches = EffectTask<Action>.run { send in
        for try await value in await process.api.uiEventBatches {
          guard !Task.isCancelled else {
            return
          }
          await send(.applyUIEventsBatch(value))
          await send(.runCursorBlinking)
        }
      }

      let reportKeyPresses = EffectTask<Action>.run { send in
        for await keyPress in keyPresses {
          guard !Task.isCancelled else {
            return
          }

          do {
            _ = try await process.api.nvimInput(
              keys: keyPress.makeNvimKeyCode()
            )
            .get()

          } catch {
            await send(.handleError(error))
          }
        }
      }

      let reportMouseEvents = EffectTask<Action>.run { send in
        for await mouseEvent in mouseEvents {
          guard !Task.isCancelled else {
            return
          }

          let rawButton: String
          let rawAction: String

          switch mouseEvent.content {
          case let .mouse(button, action):
            rawButton = button.rawValue
            rawAction = action.rawValue

          case let .scrollWheel(direction):
            rawButton = "wheel"
            rawAction = direction.rawValue
          }

          do {
            _ = try await process.api.nvimInputMouse(
              button: rawButton,
              action: rawAction,
              modifier: "",
              grid: mouseEvent.gridID.rawValue,
              row: mouseEvent.point.row,
              col: mouseEvent.point.column
            )
            .get()

          } catch {
            await send(.handleError(error))
          }
        }
      }

      let reportTabSelections = EffectTask<Action>.run { send in
        for await tabpage in tabSelections {
          guard !Task.isCancelled else {
            return
          }

          do {
            _ = try await process.api.nvimSetCurrentTabpage(
              tabpage: tabpage
            )
            .get()

          } catch {
            await send(.handleError(error))
          }
        }
      }

      let requestUIAttach = EffectTask<Action>.run { send in
        do {
          let uiOptions: UIOptions = [
            .extMultigrid,
            .extHlstate,
            .extCmdline,
            .extMessages,
            .extPopupmenu,
            .extTabline,
          ]

          _ = try await process.api.nvimUIAttach(
            width: 190,
            height: 56,
            options: uiOptions
              .nvimUIAttachOptions
          )
          .get()

        } catch {
          await send(.handleError(error))
        }
      }

      return .merge(
        applyUIEventBatches,
        reportKeyPresses,
        reportMouseEvents,
        reportTabSelections,
        requestUIAttach
      )
      .cancellable(id: EffectID.bindProcess)

    case let .applyUIEventsBatch(uiEventsBatch):
      state.bufferedUIEvents += uiEventsBatch

      if uiEventsBatch.last.flatMap(/UIEvent.flush) != nil {
        var isInstanceUpdated = false
        var isGridsLayoutUpdated = false
        var isCmdlineUpdated = false

        var gridUpdates = [Grid.ID: [IntegerRectangle]]()
        func appendGridUpdate(gridID: Grid.ID, frame: IntegerRectangle) {
          update(&gridUpdates[gridID]) { updates in
            if updates == nil {
              updates = []
            }

            updates!.append(frame)
          }
        }

        var uiEvents = [UIEvent]()
        swap(&uiEvents, &state.bufferedUIEvents)

        uiEvents: for uiEvent in uiEvents {
          switch uiEvent {
          case let .setTitle(title):
            state.title = title

            isInstanceUpdated = true

          case let .modeInfoSet(enabled, cursorStyles):
            state.modeInfo = ModeInfo(
              enabled: enabled,
              cursorStyles: cursorStyles
                .compactMap { rawCursorStyle -> CursorStyle? in
                  guard case let .dictionary(rawCursorStyle) = rawCursorStyle else {
                    assertionFailure("Invalid cursor style raw value type")
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
                      .flatMap((/Value.integer).extract(from:))
                      .map(Highlight.ID.init(rawValue:)),
                    attrIDLm: rawCursorStyle["attr_id_lm"]
                      .flatMap((/Value.integer).extract(from:))
                  )
                }
            )

            isInstanceUpdated = true

          case let .optionSet(name, value):
            state.rawOptions.updateValue(
              value,
              forKey: name,
              insertingAt: state.rawOptions.count
            )

            isInstanceUpdated = true

          case let .modeChange(name, cursorStyleIndex):
            state.mode = .init(
              name: name,
              cursorStyleIndex: cursorStyleIndex
            )

            if let cursor = state.cursor {
              appendGridUpdate(
                gridID: cursor.gridID,
                frame: .init(
                  origin: .init(column: cursor.position.column, row: cursor.position.row),
                  size: .init(columnsCount: 1, rowsCount: 1)
                )
              )
            }

          case let .defaultColorsSet(rgbFg, rgbBg, rgbSp, _, _):
            state.highlights.updateOrAppend(
              .init(
                id: .default,
                foregroundColor: .init(rgb: rgbFg),
                backgroundColor: .init(rgb: rgbBg),
                specialColor: .init(rgb: rgbSp)
              )
            )

            isInstanceUpdated = true

          case let .hlAttrDefine(rawID, rgbAttrs, _, _):
            let id = Highlight.ID(rawID)

            update(&state.highlights[id: id]) { highlight in
              if highlight == nil {
                highlight = .init(id: id)
              }

              for (key, value) in rgbAttrs {
                guard case let .string(key) = key else {
                  continue
                }

                switch key {
                case "foreground":
                  if case let .integer(value) = value {
                    highlight!.foregroundColor = .init(rgb: value)
                  }

                case "background":
                  if case let .integer(value) = value {
                    highlight!.backgroundColor = .init(rgb: value)
                  }

                case "special":
                  if case let .integer(value) = value {
                    highlight!.specialColor = .init(rgb: value)
                  }

                case "bold":
                  if case let .boolean(value) = value {
                    highlight!.isBold = value
                  }

                case "italic":
                  if case let .boolean(value) = value {
                    highlight!.isItalic = value
                  }

                default:
                  break
                }
              }
            }

            isInstanceUpdated = true

          case let .gridResize(rawID, width, height):
            let id = Grid.ID(rawID)
            let size = IntegerSize(
              columnsCount: width,
              rowsCount: height
            )

            update(&state.grids[id: id]) { grid in
              if grid == nil {
                let cells = TwoDimensionalArray<Cell>(
                  size: size,
                  repeatingElement: .default
                )

                grid = .init(
                  id: id,
                  cells: cells,
                  rowLayouts: cells.rows
                    .map(RowLayout.init(rowCells:)),
                  windowID: nil,
                  updates: [],
                  updateFlag: true
                )

              } else {
                let newCells = TwoDimensionalArray<Cell>(
                  size: size,
                  elementAtPoint: { point in
                    guard
                      point.row < grid!.cells.rowsCount,
                      point.column < grid!.cells.columnsCount
                    else {
                      return .default
                    }

                    return grid!.cells[point]
                  }
                )

                grid!.cells = newCells
                grid!.rowLayouts = newCells.rows
                  .map(RowLayout.init(rowCells:))
              }
            }

            if
              let cursor = state.cursor,
              cursor.gridID == id,
              cursor.position.column >= size.columnsCount,
              cursor.position.row >= size.rowsCount
            {
              state.cursor = nil
            }

            if id == .outer {
              isInstanceUpdated = true
            }

            isGridsLayoutUpdated = true

          case let .gridLine(rawID, row, startColumn, data):
            let id = Grid.ID(rawID)

            update(&state.grids[id: id]!.cells.rows[row]) { rowCells in
              var updatedCellsCount = 0
              var highlightID = Highlight.ID.default

              for value in data {
                guard
                  let arrayValue = (/Value.array).extract(from: value),
                  !arrayValue.isEmpty,
                  let text = (/Value.string).extract(from: arrayValue[0])
                else {
                  assertionFailure("Raw value is not an array or first element is not a text")
                  continue
                }

                var repeatCount = 1

                if arrayValue.count > 1 {
                  guard
                    let newHighlightID = (/Value.integer).extract(from: arrayValue[1])
                  else {
                    assertionFailure("Second array element is not an integer highlight id")
                    continue
                  }

                  highlightID = .init(rawValue: newHighlightID)

                  if arrayValue.count > 2 {
                    guard
                      let newRepeatCount = (/Value.integer).extract(from: arrayValue[2])
                    else {
                      assertionFailure("Third array element is not an integer repeat count")
                      continue
                    }

                    repeatCount = newRepeatCount
                  }
                }

                for _ in 0 ..< repeatCount {
                  let cell = Cell(
                    text: text,
                    highlightID: highlightID
                  )

                  let index = rowCells.index(
                    rowCells.startIndex,
                    offsetBy: startColumn + updatedCellsCount
                  )
                  rowCells[index] = cell

                  updatedCellsCount += 1
                }
              }
            }

            update(&state.grids[id: id]!) { grid in
              grid.rowLayouts[row] = .init(
                rowCells: grid.cells.rows[row]
              )
            }

            appendGridUpdate(gridID: id, frame: .init(
              origin: .init(column: 0, row: row),
              size: .init(columnsCount: state.grids[id: id]!.cells.size.columnsCount, rowsCount: 1)
            ))

          case let .gridScroll(rawGridID, top, bottom, _, _, rowsCount, _):
            let gridID = Grid.ID(rawValue: rawGridID)

            update(&state.grids[id: gridID]!) { grid in
              let gridCopy = grid

              for fromRow in top ..< bottom {
                let toRow = fromRow - rowsCount

                guard toRow >= 0, toRow < grid.cells.rowsCount else {
                  continue
                }

                grid.cells.rows[toRow] = gridCopy.cells.rows[fromRow]
                grid.rowLayouts[toRow] = gridCopy.rowLayouts[fromRow]
              }
            }

            let frame = IntegerRectangle(
              origin: .init(column: 0, row: top + min(0, rowsCount)),
              size: .init(
                columnsCount: state.grids[id: gridID]!.cells.size.columnsCount,
                rowsCount: bottom - top - min(0, rowsCount) + max(0, rowsCount)
              )
            )
            appendGridUpdate(gridID: gridID, frame: frame)

          case let .gridClear(rawGridID):
            let gridID = Grid.ID(rawGridID)

            update(&state.grids[id: gridID]!) { grid in
              let newCells = TwoDimensionalArray<Cell>(
                size: grid.cells.size,
                repeatingElement: .default
              )

              grid.cells = newCells
              grid.rowLayouts = newCells.rows
                .map(RowLayout.init(rowCells:))
            }

            let grid = state.grids[id: gridID]!
            appendGridUpdate(gridID: gridID, frame: .init(
              origin: .init(column: 0, row: 0),
              size: grid.cells.size
            ))

          case let .gridDestroy(rawGridID):
            let gridID = Grid.ID(rawGridID)
            guard var grid = state.grids[id: gridID] else {
              continue
            }

            if let windowID = grid.windowID {
              let window = state.windows.remove(id: windowID)

              if window == nil {
                state.floatingWindows.remove(id: windowID)
              }

              grid.windowID = nil
              state.grids.updateOrAppend(grid)
            }

            isGridsLayoutUpdated = true

          case let .gridCursorGoto(rawGridID, row, column):
            let oldCursor = state.cursor

            let gridID = Grid.ID(rawGridID)

            let cursorPosition = IntegerPoint(
              column: column,
              row: row
            )
            state.cursor = .init(
              gridID: gridID,
              position: cursorPosition
            )

            if
              let oldCursor,
              oldCursor.gridID == gridID,
              oldCursor.position.row == cursorPosition.row
            {
              let originColumn = min(oldCursor.position.column, cursorPosition.column)
              let columnsCount = max(oldCursor.position.column, cursorPosition.column) - originColumn + 1

              appendGridUpdate(
                gridID: oldCursor.gridID,
                frame: .init(
                  origin: .init(column: originColumn, row: cursorPosition.row),
                  size: .init(
                    columnsCount: columnsCount,
                    rowsCount: 1
                  )
                )
              )

            } else {
              if let oldCursor {
                appendGridUpdate(
                  gridID: oldCursor.gridID,
                  frame: IntegerRectangle(
                    origin: oldCursor.position,
                    size: .init(columnsCount: 1, rowsCount: 1)
                  )
                )
              }

              appendGridUpdate(
                gridID: gridID,
                frame: IntegerRectangle(
                  origin: cursorPosition,
                  size: .init(columnsCount: 1, rowsCount: 1)
                )
              )
            }

          case let .winPos(rawGridID, windowID, originRow, originColumn, columnsCount, rowsCount):
            state.floatingWindows.remove(id: windowID)

            let gridID = Grid.ID(rawGridID)

            state.windows.updateOrAppend(
              .init(
                reference: windowID,
                gridID: gridID,
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
                zIndex: state.nextWindowZIndex(),
                isHidden: false
              )
            )
            state.grids[id: gridID]!.windowID = windowID

            isGridsLayoutUpdated = true

          case let .winFloatPos(
            rawGridID,
            windowID,
            rawAnchor,
            rawAnchorGridID,
            anchorRow,
            anchorColumn,
            isFocusable,
            zIndex
          ):
            guard let anchor = Anchor(rawValue: rawAnchor) else {
              assertionFailure("Invalid anchor value: \(rawAnchor)")
              continue
            }

            state.windows.remove(id: windowID)

            let gridID = Grid.ID(rawGridID)

            state.floatingWindows.updateOrAppend(
              .init(
                reference: windowID,
                gridID: gridID,
                anchor: anchor,
                anchorGridID: Grid.ID(rawAnchorGridID),
                anchorRow: anchorRow,
                anchorColumn: anchorColumn,
                isFocusable: isFocusable,
                zIndex: zIndex,
                isHidden: false
              )
            )

            state.grids[id: gridID]!.windowID = windowID

            isGridsLayoutUpdated = true

          case let .winHide(rawGridID):
            let gridID = Grid.ID(rawGridID)

            if let windowID = state.grids[id: gridID]!.windowID {
              if let index = state.windows.index(id: windowID) {
                state.windows[index].isHidden = true

              } else if let index = state.floatingWindows.index(id: windowID) {
                state.floatingWindows[index].isHidden = true
              }
            }

            isGridsLayoutUpdated = true

          case let .winClose(rawGridID):
            let gridID = Grid.ID(rawGridID)

            guard var grid = state.grids[id: gridID] else {
              continue
            }

            if let windowID = grid.windowID {
              let window = state.windows.remove(id: windowID)

              if window == nil {
                state.floatingWindows.remove(id: windowID)
              }

              grid.windowID = nil
              state.grids.updateOrAppend(grid)
            }

            isGridsLayoutUpdated = true

          case let .tablineUpdate(currentTab, rawTabs, _, _):
            state.tabline = .init(
              currentTab: currentTab,
              tabs: rawTabs
                .compactMap { rawTab in
                  guard
                    case let .dictionary(rawTab) = rawTab,
                    let name = rawTab["name"]
                      .flatMap((/Value.string).extract(from:)),
                    let rawReference = rawTab["tab"]
                      .flatMap((/Value.ext).extract(from:)),
                    let reference = References.Tabpage(
                      type: rawReference.0,
                      data: rawReference.1
                    )
                  else {
                    assertionFailure("Invalid tabline raw value")
                    return nil
                  }

                  return .init(
                    name: name,
                    reference: reference
                  )
                }
            )

            isGridsLayoutUpdated = true

          case let .cmdlineShow(content, pos, firstc, prompt, indent, level):
            state.cmdlines.updateOrAppend(.init(
              contentParts: content
                .compactMap { rawContentPart in
                  guard
                    case let .array(rawContentPart) = rawContentPart,
                    rawContentPart.count == 2,
                    case let .integer(rawHighlightID) = rawContentPart[0],
                    case let .string(text) = rawContentPart[1]
                  else {
                    assertionFailure("Invalid cmdline raw value")
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
              level: level
            ))

            isCmdlineUpdated = true

          case let .cmdlinePos(pos, level):
            update(&state.cmdlines[id: level]!) { cmdline in
              cmdline.cursorPosition = pos
            }

            isCmdlineUpdated = true

//          case let .cmdlineSpecialChar(c, shift, level):
//            isCmdlineUpdated = true

          case let .cmdlineHide(level):
            state.cmdlines.remove(id: level)

            isCmdlineUpdated = true

//          case let .cmdlineBlockShow(lines):
//            isCmdlineUpdated = true

//          case .cmdlineBlockHide:
//            isCmdlineUpdated = true

          default:
            break
          }
        }

        if isInstanceUpdated {
          state.instanceUpdateFlag.toggle()
        }

        if isGridsLayoutUpdated {
          state.gridsLayoutUpdateFlag.toggle()
        }

        if isCmdlineUpdated {
          state.cmdlineUpdateFlag.toggle()
        }

        for (gridID, updates) in gridUpdates {
          update(&state.grids[id: gridID]) { grid in
            grid?.updates = updates
            grid?.updateFlag.toggle()
          }
        }
      }

      return .none

    case .runCursorBlinking:
      let setInitialCursorBlinkingPhase = EffectTask<Action>.task(
        operation: { .setCursorBlinkingPhase(true) }
      )

      guard
        let modeInfo = state.modeInfo,
        let mode = state.mode
      else {
        return setInitialCursorBlinkingPhase
      }

      let cursorStyle = modeInfo.cursorStyles[mode.cursorStyleIndex]
      guard
        let blinkWait = cursorStyle.blinkWait, blinkWait > 0,
        let blinkOff = cursorStyle.blinkOff, blinkOff > 0,
        let blinkOn = cursorStyle.blinkOn, blinkOn > 0
      else {
        return setInitialCursorBlinkingPhase
      }

      let runCursorBlinking = EffectTask<Action>.run { send in
        do {
          try await suspendingClock.sleep(for: .milliseconds(blinkWait))
          guard !Task.isCancelled else {
            return
          }
          await send(.setCursorBlinkingPhase(false))

          while true {
            try await suspendingClock.sleep(for: .milliseconds(blinkOff))
            guard !Task.isCancelled else {
              return
            }
            await send(.setCursorBlinkingPhase(true))

            try await suspendingClock.sleep(for: .milliseconds(blinkOn))
            guard !Task.isCancelled else {
              return
            }
            await send(.setCursorBlinkingPhase(false))
          }
        } catch {
          let isCancellation = error is CancellationError

          if !isCancellation {
            assertionFailure("\(error)")
          }
        }
      }
      .cancellable(id: EffectID.runCursorBlinking)

      return setInitialCursorBlinkingPhase
        .concatenate(with: .cancel(id: EffectID.runCursorBlinking))
        .concatenate(with: runCursorBlinking)

    case let .setCursorBlinkingPhase(value):
      state.cursorBlinkingPhase = value

      if let cursor = state.cursor {
        update(&state.grids[id: cursor.gridID]!) { grid in
          grid.updates = [
            .init(
              origin: cursor.position,
              size: .init(columnsCount: 1, rowsCount: 1)
            ),
          ]
          grid.updateFlag.toggle()
        }
      }

      return .none

    default:
      return .none
    }
  }

  private enum EffectID: String, Hashable {
    case bindProcess
    case runCursorBlinking
  }

  @Dependency(\.suspendingClock)
  private var suspendingClock: any Clock<Duration>
}
