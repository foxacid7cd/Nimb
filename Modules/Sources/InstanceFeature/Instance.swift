// SPDX-License-Identifier: MIT

import AppKit
import AsyncAlgorithms
import CasePaths
import ComposableArchitecture
import Dependencies
import IdentifiedCollections
import Library
import MessagePack
import Neovim
import OSLog
import Overture
import Tagged

public struct Instance: ReducerProtocol {
  public init() {}

  public enum Action: Sendable {
    case bindNeovimProcess(
      mouseEvents: AsyncStream<MouseEvent>,
      keyPresses: AsyncStream<KeyPress>
    )
    case applyUIEventsBatch([UIEvent])
    case restartCursorBlinking
    case setCursorBlinkingPhase(Bool)
    case instanceView(action: InstanceView.Action)
  }

  public func reduce(into state: inout InstanceState, action: Action) -> EffectTask<Action> {
    let process = state.process

    switch action {
    case let .bindNeovimProcess(mouseEvents, keyPresses):
      let applyUIEventBatches = EffectTask<Action>.run { send in
        for try await value in await process.api.uiEventBatches {
          guard !Task.isCancelled else {
            return
          }
          await send(.applyUIEventsBatch(value))
        }
      }

      let reportKeyPresses = EffectTask<Action>.run { _ in
        for await keyPress in keyPresses {
          guard !Task.isCancelled else {
            return
          }

          do {
            try await process.api.nvimInputFast(
              keys: keyPress.makeNvimKeyCode()
            )

          } catch {
            assertionFailure("\(error)")
          }
        }
      }

      let reportMouseEvents = EffectTask<Action>.run { _ in
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
            try await process.api.nvimInputMouseFast(
              button: rawButton,
              action: rawAction,
              modifier: "",
              grid: mouseEvent.gridID.rawValue,
              row: mouseEvent.point.row,
              col: mouseEvent.point.column
            )
          } catch {
            assertionFailure("\(error)")
          }
        }
      }

      let requestUIAttach = EffectTask<Action>.run { _ in
        do {
          let uiOptions: UIOptions = [
            .extMultigrid,
            .extHlstate,
            .extCmdline,
            .extMessages,
            .extPopupmenu,
            .extTabline,
          ]

          try await process.api.nvimUIAttachFast(
            width: 200,
            height: 60,
            options: uiOptions.nvimUIAttachOptions
          )

        } catch {
          assertionFailure("\(error)")
        }
      }

      let bindProcess = EffectTask<Action>.merge(
        applyUIEventBatches,
        requestUIAttach
          .concatenate(
            with: .merge(
              reportKeyPresses,
              reportMouseEvents
            )
          )
      )
      .cancellable(id: EffectID.bindProcess)

      return .concatenate(
        .cancel(id: EffectID.bindProcess),
        bindProcess
      )

    case let .applyUIEventsBatch(uiEventsBatch):
      state.bufferedUIEvents += uiEventsBatch

      if uiEventsBatch.last.flatMap(/UIEvent.flush) != nil {
        var isInstanceUpdated = false
        var isCmdlineUpdated = false
        var isCursorUpdated = false

        var updatedGridIDs = Set<Grid.ID>()

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

            isCursorUpdated = true

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
//              appendGridUpdate(
//                gridID: cursor.gridID,
//                frame: .init(
//                  origin: .init(column: cursor.position.column, row: cursor.position.row),
//                  size: .init(columnsCount: 1, rowsCount: 1)
//                )
//              )

              isCursorUpdated = true
            }

          case let .defaultColorsSet(rgbFg, rgbBg, rgbSp, _, _):
            state.defaultForegroundColor = .init(rgb: rgbFg)
            state.defaultBackgroundColor = .init(rgb: rgbBg)
            state.defaultSpecialColor = .init(rgb: rgbSp)

            isInstanceUpdated = true

          case let .hlAttrDefine(rawID, rgbAttrs, _, _):
            let id = Highlight.ID(rawID)

            update(&state.highlights[rawID]) { highlight in
              if highlight == nil {
                highlight = .init(
                  id: id,
                  foregroundColor: nil,
                  backgroundColor: nil,
                  specialColor: nil,
                  isReverse: false,
                  isItalic: false,
                  isBold: false,
                  decorations: .init(),
                  blend: 0
                )
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

                case "reverse":
                  if case let .boolean(value) = value {
                    highlight!.isReverse = value
                  }

                case "italic":
                  if case let .boolean(value) = value {
                    highlight!.isItalic = value
                  }

                case "bold":
                  if case let .boolean(value) = value {
                    highlight!.isBold = value
                  }

                case "strikethrough":
                  if case let .boolean(value) = value {
                    highlight!.decorations.isStrikethrough = value
                  }

                case "underline":
                  if case let .boolean(value) = value {
                    highlight!.decorations.isUnderline = value
                  }

                case "undercurl":
                  if case let .boolean(value) = value {
                    highlight!.decorations.isUndercurl = value
                  }

                case "underdouble":
                  if case let .boolean(value) = value {
                    highlight!.decorations.isUnderdouble = value
                  }

                case "underdotted":
                  if case let .boolean(value) = value {
                    highlight!.decorations.isUnderdotted = value
                  }

                case "underdashed":
                  if case let .boolean(value) = value {
                    highlight!.decorations.isUnderdashed = value
                  }

                case "blend":
                  if case let .integer(value) = value {
                    highlight!.blend = value
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

            update(&state.grids[rawID]) { grid in
              if grid == nil {
                let cells = TwoDimensionalArray<Grid.Cell>(
                  size: size,
                  repeatingElement: .default
                )

                grid = .init(
                  id: id,
                  cells: cells,
                  rowLayouts: cells.rows
                    .map(Grid.RowLayout.init(rowCells:)),
                  updates: [],
                  updateFlag: true,
                  asssociatedWindow: nil,
                  isHidden: false
                )

              } else {
                let newCells = TwoDimensionalArray<Grid.Cell>(
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
                  .map(Grid.RowLayout.init(rowCells:))
              }
            }

            if
              let cursor = state.cursor,
              cursor.gridID == id,
              cursor.position.column >= size.columnsCount,
              cursor.position.row >= size.rowsCount
            {
              state.cursor = nil

              isCursorUpdated = true
            }

            if id == .outer {
              isInstanceUpdated = true
            }

            updatedGridIDs.insert(id)

          case let .gridLine(rawID, row, startColumn, data):
            let id = Grid.ID(rawID)

            update(&state.grids[id]!.cells.rows[row]) { rowCells in
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
                  let cell = Grid.Cell(
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

            update(&state.grids[id]!) { grid in
              grid.rowLayouts[row] = .init(
                rowCells: grid.cells.rows[row]
              )
            }

//            appendGridUpdate(gridID: id, frame: .init(
//              origin: .init(column: 0, row: row),
//              size: .init(columnsCount: state.grids[id]!.cells.size.columnsCount, rowsCount: 1)
//            ))

          case let .gridScroll(rawGridID, top, bottom, _, _, rowsCount, _):
            let gridID = Grid.ID(rawValue: rawGridID)

            update(&state.grids[gridID]!) { grid in
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

//            let frame = IntegerRectangle(
//              origin: .init(column: 0, row: top + min(0, rowsCount)),
//              size: .init(
//                columnsCount: state.grids[gridID]!.cells.size.columnsCount,
//                rowsCount: bottom - top - min(0, rowsCount) + max(0, rowsCount)
//              )
//            )
//            appendGridUpdate(gridID: gridID, frame: frame)

          case let .gridClear(rawGridID):
            let gridID = Grid.ID(rawGridID)

            update(&state.grids[gridID]!) { grid in
              let newCells = TwoDimensionalArray<Grid.Cell>(
                size: grid.cells.size,
                repeatingElement: .default
              )

              grid.cells = newCells
              grid.rowLayouts = newCells.rows
                .map(Grid.RowLayout.init(rowCells:))
            }

//            let grid = state.grids[gridID]!
//            appendGridUpdate(gridID: gridID, frame: .init(
//              origin: .init(column: 0, row: 0),
//              size: grid.cells.size
//            ))

          case let .gridDestroy(rawGridID):
            let gridID = Grid.ID(rawGridID)

            state.grids[gridID]?.asssociatedWindow = nil

            updatedGridIDs.insert(gridID)

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
//              let originColumn = min(oldCursor.position.column, cursorPosition.column)
//              let columnsCount = max(oldCursor.position.column, cursorPosition.column) - originColumn + 1
//
//              appendGridUpdate(
//                gridID: oldCursor.gridID,
//                frame: .init(
//                  origin: .init(column: originColumn, row: cursorPosition.row),
//                  size: .init(
//                    columnsCount: columnsCount,
//                    rowsCount: 1
//                  )
//                )
//              )

            } else {
//              if let oldCursor {
//                appendGridUpdate(
//                  gridID: oldCursor.gridID,
//                  frame: IntegerRectangle(
//                    origin: oldCursor.position,
//                    size: .init(columnsCount: 1, rowsCount: 1)
//                  )
//                )
//              }
//
//              appendGridUpdate(
//                gridID: gridID,
//                frame: IntegerRectangle(
//                  origin: cursorPosition,
//                  size: .init(columnsCount: 1, rowsCount: 1)
//                )
//              )
            }

            isCursorUpdated = true

          case let .winPos(rawGridID, windowID, originRow, originColumn, columnsCount, rowsCount):
            let gridID = Grid.ID(rawGridID)

            let zIndex = state.nextWindowZIndex()
            state.grids[gridID]?.asssociatedWindow = .plain(
              .init(
                reference: windowID,
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

            updatedGridIDs.insert(gridID)

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

            let gridID = Grid.ID(rawGridID)

            state.grids[gridID]?.asssociatedWindow = .floating(
              .init(
                reference: windowID,
                anchor: anchor,
                anchorGridID: Grid.ID(rawAnchorGridID),
                anchorRow: anchorRow,
                anchorColumn: anchorColumn,
                isFocusable: isFocusable,
                zIndex: zIndex
              )
            )

            updatedGridIDs.insert(gridID)

          case let .winHide(rawGridID):
            let gridID = Grid.ID(rawGridID)

            state.grids[rawGridID]?.isHidden = true

            updatedGridIDs.insert(gridID)

          case let .winClose(rawGridID):
            let gridID = Grid.ID(rawValue: rawGridID)

            state.grids[rawGridID]?.asssociatedWindow = nil

            updatedGridIDs.insert(gridID)

          case let .tablineUpdate(currentTabID, rawTabs, _, _):
            let tabs = rawTabs
              .compactMap { rawTab -> Tab? in
                guard
                  case let .dictionary(rawTab) = rawTab,
                  let name = rawTab["name"]
                    .flatMap((/Value.string).extract(from:)),
                  let rawID = rawTab["tab"]
                    .flatMap((/Value.ext).extract(from:)),
                  let id = References.Tabpage(
                    type: rawID.0,
                    data: rawID.1
                  )
                else {
                  assertionFailure("Invalid tabline raw value")
                  return nil
                }

                return .init(
                  id: id,
                  name: name
                )
              }

            state.tabline = .init(
              currentTabID: currentTabID,
              tabs: .init(uniqueElements: tabs)
            )

//            isGridsLayoutUpdated = true

          case let .cmdlineShow(content, pos, firstc, prompt, indent, level):
            state.cmdlines[level] = .init(
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
              level: level,
              specialCharacter: "",
              shiftAfterSpecialCharacter: false,
              blockLines: []
            )

            isCmdlineUpdated = true

          case let .cmdlinePos(pos, level):
            update(&state.cmdlines[level]!) { cmdline in
              cmdline.cursorPosition = pos
            }

            isCmdlineUpdated = true

          case let .cmdlineSpecialChar(c, shift, level):
            update(&state.cmdlines[level]!) { cmdline in
              cmdline.specialCharacter = c
              cmdline.shiftAfterSpecialCharacter = shift
            }

            isCmdlineUpdated = true

          case let .cmdlineHide(level):
            state.cmdlines.removeValue(forKey: level)

            isCmdlineUpdated = true

          case let .cmdlineBlockShow(lines):
            var blockLines = [[CmdlineContentPart]]()

            for line in lines {
              guard case let .array(line) = line else {
                continue
              }

              var contentParts = [CmdlineContentPart]()

              for rawContentPart in line {
                guard
                  case let .array(rawContentPart) = rawContentPart,
                  rawContentPart.count == 2,
                  case let .integer(rawHighlightID) = rawContentPart[0],
                  case let .string(text) = rawContentPart[1]
                else {
                  assertionFailure("Invalid cmdline raw value")
                  continue
                }

                contentParts.append(
                  .init(
                    highlightID: .init(rawHighlightID),
                    text: text
                  )
                )
              }

              blockLines.append(contentParts)
            }

            if !state.cmdlines.isEmpty {
              update(&state.cmdlines[state.cmdlines.count - 1]) { cmdline in
                cmdline?.blockLines = blockLines
              }
            }

            isCmdlineUpdated = true

          case .cmdlineBlockHide:
            if !state.cmdlines.isEmpty {
              update(&state.cmdlines[state.cmdlines.count - 1]) { cmdline in
                cmdline?.blockLines = []
              }
            }

            isCmdlineUpdated = true

          default:
            break
          }
        }

        if isInstanceUpdated {
          state.instanceUpdateFlag.toggle()
        }

        if isCmdlineUpdated {
          state.cmdlineUpdateFlag.toggle()
        }

        if !state.updatedGridIDs.isEmpty {
          state.updatedGridIDs = updatedGridIDs
          state.gridsUpdateFlag.toggle()
        }

        if isCursorUpdated || isCmdlineUpdated {
          return .send(.restartCursorBlinking)

        } else {
          return .none
        }
      }

      return .none

    case .restartCursorBlinking:
      state.cursorBlinkingPhase = true

      let cancelPreviousTask = EffectTask<Action>.cancel(id: EffectID.cursorBlinking)

      guard state.cursor != nil, let modeInfo = state.modeInfo, let mode = state.mode else {
        return cancelPreviousTask
      }
      let cursorStyle = modeInfo.cursorStyles[mode.cursorStyleIndex]

      guard
        let blinkWait = cursorStyle.blinkWait, blinkWait > 0,
        let blinkOff = cursorStyle.blinkOff, blinkOff > 0,
        let blinkOn = cursorStyle.blinkOn, blinkOn > 0
      else {
        return cancelPreviousTask
      }

      let task = EffectTask<Action>.run { send in
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
      .cancellable(id: EffectID.cursorBlinking)

      return .concatenate(cancelPreviousTask, task)

    case let .setCursorBlinkingPhase(value):
      state.cursorBlinkingPhase = value

      if let cursor = state.cursor, state.cmdlines.isEmpty {
        update(&state.grids[cursor.gridID]!) { grid in
          grid.updates.append(
            .init(
              origin: cursor.position,
              size: .init(columnsCount: 1, rowsCount: 1)
            )
          )
          grid.updateFlag.toggle()
        }
      }

      return .none

    case let .instanceView(action):
      switch action {
      case let .headerView(action):
        switch action {
        case let .reportSelectedTab(id):
          return .fireAndForget {
            do {
              _ = try await process.api.nvimSetCurrentTabpage(tabpage: id)
                .get()

            } catch {
              assertionFailure("\(error)")
            }
          }

        case .sideMenuButtonPressed:
          return .none
        }
      }
    }
  }

  private enum EffectID: String, Hashable {
    case bindProcess
    case cursorBlinking
  }

  @Dependency(\.suspendingClock)
  private var suspendingClock: any Clock<Duration>
}
