// SPDX-License-Identifier: MIT

import CasePaths
import Collections
import CustomDump
import IdentifiedCollections
import Library
import MessagePack
import Overture
import Tagged

public struct State: Sendable {
  public init(
    bufferedUIEvents: [UIEvent] = [],
    rawOptions: OrderedDictionary<String, Value> = [:],
    title: String? = nil,
    appearance: Appearance = .init(),
    modeInfo: ModeInfo? = nil,
    mode: Mode? = nil,
    cursor: Cursor? = nil,
    tabline: Tabline? = nil,
    cmdlines: IdentifiedArrayOf<Cmdline> = [],
    msgShows: [MsgShow] = [],
    grids: IntKeyedDictionary<Grid> = [:]
  ) {
    self.bufferedUIEvents = bufferedUIEvents
    self.rawOptions = rawOptions
    self.title = title
    self.appearance = appearance
    self.modeInfo = modeInfo
    self.mode = mode
    self.cursor = cursor
    self.tabline = tabline
    self.cmdlines = cmdlines
    self.msgShows = msgShows
    self.grids = grids
  }

  public var bufferedUIEvents: [UIEvent]
  public var rawOptions: OrderedDictionary<String, Value>
  public var title: String?
  public var appearance: Appearance
  public var modeInfo: ModeInfo?
  public var mode: Mode?
  public var cursor: Cursor?
  public var tabline: Tabline?
  public var cmdlines: IdentifiedArrayOf<Cmdline>
  public var lastCmdlineLevel: Int?
  public var msgShows: [MsgShow]
  public var grids: IntKeyedDictionary<Grid>
  public var windowZIndexCounter = 0
  public var popupmenu: Popupmenu?

  public mutating func nextWindowZIndex() -> Int {
    windowZIndexCounter += 1
    return windowZIndexCounter
  }

  public var currentCursorStyle: CursorStyle? {
    guard let modeInfo, let mode, mode.cursorStyleIndex < modeInfo.cursorStyles.count else {
      return nil
    }

    return modeInfo.cursorStyles[mode.cursorStyleIndex]
  }
}

public extension State {
  struct Updates: Sendable {
    public init(
      isTitleUpdated: Bool = false,
      isAppearanceUpdated: Bool = false,
      isTablineUpdated: Bool = false,
      isCmdlinesUpdated: Bool = false,
      isMsgShowsUpdated: Bool = false,
      isCursorUpdated: Bool = false,
      updatedLayoutGridIDs: Set<Grid.ID> = Set<Grid.ID>(),
      gridUpdatedRectangles: [Grid.ID: [IntegerRectangle]] = [Grid.ID: [IntegerRectangle]](),
      isPopupmenuUpdated: Bool = false
    ) {
      self.isTitleUpdated = isTitleUpdated
      self.isAppearanceUpdated = isAppearanceUpdated
      self.isTablineUpdated = isTablineUpdated
      self.isCmdlinesUpdated = isCmdlinesUpdated
      self.isMsgShowsUpdated = isMsgShowsUpdated
      self.isCursorUpdated = isCursorUpdated
      self.updatedLayoutGridIDs = updatedLayoutGridIDs
      self.gridUpdatedRectangles = gridUpdatedRectangles
      self.isPopupmenuUpdated = isPopupmenuUpdated
    }

    public var isTitleUpdated = false
    public var isAppearanceUpdated = false
    public var isTablineUpdated = false
    public var isCmdlinesUpdated = false
    public var isMsgShowsUpdated = false
    public var isCursorUpdated = false
    public var updatedLayoutGridIDs = Set<Grid.ID>()
    public var gridUpdatedRectangles = [Grid.ID: [IntegerRectangle]]()
    public var isPopupmenuUpdated = false
    public var isPopupmenuSelectionUpdated = false
  }

  mutating func apply(uiEvents: [UIEvent]) -> Updates? {
    bufferedUIEvents += uiEvents

    if uiEvents.last.flatMap(/UIEvent.flush) != nil {
      var updates = Updates()

      func titleUpdated() {
        updates.isTitleUpdated = true
      }

      func appearanceUpdated() {
        updates.isAppearanceUpdated = true
      }

      func tablineUpdated() {
        updates.isTablineUpdated = true
      }

      func cmdlinesUpdated() {
        updates.isCmdlinesUpdated = true
      }

      func msgShowsUpdated() {
        updates.isMsgShowsUpdated = true
      }

      func cursorUpdated() {
        updates.isCursorUpdated = true
      }

      func updatedLayout(forGridWithID gridID: Grid.ID) {
        updates.updatedLayoutGridIDs.insert(gridID)
      }

      func updatedCells(inGridWithID gridID: Grid.ID, rectangles: [IntegerRectangle]) {
        update(&updates.gridUpdatedRectangles[gridID]) { accumulator in
          accumulator = (accumulator ?? []) + rectangles
        }
      }

      func updatedAllCells(inGrid grid: Grid) {
        updates.gridUpdatedRectangles.removeValue(forKey: grid.id)

        updatedCells(
          inGridWithID: grid.id,
          rectangles: [
            .init(
              origin: .init(),
              size: grid.cells.size
            ),
          ]
        )
      }

      func popupmenuUpdated() {
        updates.isPopupmenuUpdated = true
      }

      func popupmenuSelectionUpdated() {
        updates.isPopupmenuSelectionUpdated = true
      }

      func blockLines(fromRawLines rawLines: [Value]) -> [[Cmdline.ContentPart]] {
        var blockLines = [[Cmdline.ContentPart]]()

        for line in rawLines {
          guard case let .array(line) = line else {
            continue
          }

          var contentParts = [Cmdline.ContentPart]()

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

        return blockLines
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

          if let cursor {
            updatedCells(
              inGridWithID: cursor.gridID,
              rectangles: [.init(
                origin: .init(column: max(0, cursor.position.column - 1), row: cursor.position.row),
                size: .init(columnsCount: 3, rowsCount: 1)
              )]
            )

            cursorUpdated()
          }

        case let .defaultColorsSet(rgbFg, rgbBg, rgbSp, _, _):
          appearance.defaultForegroundColor = .init(rgb: rgbFg)
          appearance.defaultBackgroundColor = .init(rgb: rgbBg)
          appearance.defaultSpecialColor = .init(rgb: rgbSp)

          appearanceUpdated()

        case let .hlAttrDefine(rawHighlightID, rgbAttrs, _, _):
          let highlightID = Highlight.ID(rawHighlightID)

          update(&appearance.highlights[highlightID]) { highlight in
            if highlight == nil {
              highlight = .init(
                id: highlightID,
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

          appearanceUpdated()

        case let .gridResize(gridID, width, height):
          let size = IntegerSize(
            columnsCount: width,
            rowsCount: height
          )

          update(&grids[gridID]) { grid in
            if grid == nil {
              let cells = TwoDimensionalArray<Grid.Cell>(
                size: size,
                repeatingElement: .default
              )

              grid = .init(
                id: gridID,
                cells: cells,
                rowLayouts: cells.rows
                  .map(Grid.RowLayout.init(rowCells:)),
                associatedWindow: nil,
                isHidden: false
              )

            } else {
              let newCells = TwoDimensionalArray<Grid.Cell>(
                size: size,
                elementAtPoint: { point in
                  guard
                    point.row < grid!.cells.rows.count,
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
            let cursor,
            cursor.gridID == gridID,
            cursor.position.column >= size.columnsCount,
            cursor.position.row >= size.rowsCount
          {
            self.cursor = nil

            cursorUpdated()
          }

          updatedLayout(forGridWithID: gridID)

        case let .gridLine(gridID, row, startColumn, data, _):
          var updatedCellsCount = 0
          var highlightID = Highlight.ID.default

          update(&grids[gridID]!.cells.rows[row]) { rowCells in
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

          update(&grids[gridID]!) { grid in
            grid.rowLayouts[row] = .init(
              rowCells: grid.cells.rows[row]
            )
          }

          updatedCells(inGridWithID: gridID, rectangles: [.init(
            origin: .init(column: startColumn, row: row),
            size: .init(columnsCount: updatedCellsCount, rowsCount: 1)
          )])

        case let .gridScroll(gridID, top, bottom, _, _, rowsCount, _):
          update(&grids[gridID]!) { grid in
            let gridCopy = grid

            for fromRow in top ..< bottom {
              let toRow = fromRow - rowsCount

              guard toRow >= 0, toRow < grid.cells.rows.count else {
                continue
              }

              grid.cells.rows[toRow] = gridCopy.cells.rows[fromRow]
              grid.rowLayouts[toRow] = gridCopy.rowLayouts[fromRow]
            }
          }

          let rectangle = IntegerRectangle(
            origin: .init(column: 0, row: top + min(0, rowsCount)),
            size: .init(
              columnsCount: grids[gridID]!.cells.size.columnsCount,
              rowsCount: bottom - top - min(0, rowsCount) + max(0, rowsCount)
            )
          )
          updatedCells(inGridWithID: gridID, rectangles: [rectangle])

        case let .gridClear(gridID):
          update(&grids[gridID]!) { grid in
            let newCells = TwoDimensionalArray<Grid.Cell>(
              size: grid.cells.size,
              repeatingElement: .default
            )

            grid.cells = newCells
            grid.rowLayouts = newCells.rows
              .map(Grid.RowLayout.init(rowCells:))

            updatedAllCells(inGrid: grid)
          }

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

          if
            let oldCursor,
            oldCursor.gridID == gridID,
            oldCursor.position.row == cursorPosition.row
          {
            let originColumn = min(oldCursor.position.column, cursorPosition.column)
            let columnsCount = max(oldCursor.position.column, cursorPosition.column) - originColumn + 1
            updatedCells(inGridWithID: oldCursor.gridID, rectangles: [.init(
              origin: .init(column: originColumn, row: cursorPosition.row),
              size: .init(
                columnsCount: columnsCount,
                rowsCount: 1
              )
            )])

          } else {
            if let oldCursor {
              updatedCells(
                inGridWithID: oldCursor.gridID,
                rectangles: [.init(
                  origin: oldCursor.position,
                  size: .init(columnsCount: 1, rowsCount: 1)
                )]
              )
            }

            updatedCells(
              inGridWithID: gridID,
              rectangles: [.init(
                origin: cursorPosition,
                size: .init(columnsCount: 1, rowsCount: 1)
              )]
            )
          }

          cursorUpdated()

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
            assertionFailure("Invalid anchor value: \(rawAnchor)")
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

        case let .tablineUpdate(currentTabpageID, rawTabpages, _, _):
          let tabpages = rawTabpages
            .compactMap { rawTabpage -> Tabpage? in
              guard
                case let .dictionary(rawTab) = rawTabpage,
                let name = rawTab["name"]
                  .flatMap((/Value.string).extract(from:)),
                let rawID = rawTab["tab"]
                  .flatMap((/Value.ext).extract(from:))
              else {
                assertionFailure("Invalid tabline raw value")
                return nil
              }

              return .init(
                id: .init(
                  .init(
                    type: rawID.0,
                    data: rawID.1
                  )!
                ),
                name: name
              )
            }

          tabline = .init(
            currentTabpageID: currentTabpageID,
            tabpages: .init(uniqueElements: tabpages)
          )

          tablineUpdated()

        case let .cmdlineShow(content, pos, firstc, prompt, indent, level):
          let oldCmdline = cmdlines[id: level]

          let cmdline = Cmdline(
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
            blockLines: oldCmdline?.blockLines ?? [],
            isVisible: true
          )

          lastCmdlineLevel = level

          cmdlines[id: level] = cmdline
          cmdlinesUpdated()

        case let .cmdlinePos(pos, level):
          update(&cmdlines[id: level]!) { cmdline in
            cmdline.cursorPosition = pos
          }

          lastCmdlineLevel = level

          cmdlinesUpdated()

        case let .cmdlineSpecialChar(c, shift, level):
          update(&cmdlines[id: level]!) { cmdline in
            cmdline.specialCharacter = c
            cmdline.shiftAfterSpecialCharacter = shift
          }

          cmdlinesUpdated()

        case let .cmdlineHide(level):
          update(&cmdlines[id: level]!) { cmdline in
            cmdline.isVisible = false
          }

          cmdlinesUpdated()

        case let .cmdlineBlockShow(rawLines):
          cmdlines[id: lastCmdlineLevel!]!.blockLines = blockLines(fromRawLines: rawLines)

          cmdlinesUpdated()

        case let .cmdlineBlockAppend(rawLine):
          update(&cmdlines[id: lastCmdlineLevel!]!) { cmdline in
            cmdline.blockLines += blockLines(fromRawLines: [.array(rawLine)])
          }

          cmdlinesUpdated()

        case .cmdlineBlockHide:
          if let lastCmdlineLevel {
            update(&cmdlines[id: lastCmdlineLevel]!) { cmdline in
              cmdline.blockLines = []
            }
          }

          cmdlinesUpdated()

        case let .msgShow(kind, content, replaceLast):
          if replaceLast, !msgShows.isEmpty {
            msgShows.removeLast()
          }

          if !content.isEmpty {
            let msgShow = MsgShow(
              index: msgShows.count,
              kind: kind,
              contentParts: content
                .compactMap { rawContentPart in
                  guard
                    case let .array(rawContentPart) = rawContentPart,
                    rawContentPart.count == 2,
                    case let .integer(rawHighlightID) = rawContentPart[0],
                    case let .string(text) = rawContentPart[1]
                  else {
                    assertionFailure("Invalid msgShow content raw value")
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
              var dump = ""
              customDump(rawItem, to: &dump)
              assertionFailure("Failed decoding PopupmenuItem:\n\(dump)")

              items.append(.init(word: "ERROR", kind: "", menu: "", info: ""))
            }
          }

          let selectedItemIndex: Int? = selected >= 0 ? selected : nil

          let anchor: Popupmenu.Anchor = switch gridID.rawValue {
          case -1:
            .cmdline(origin: col)

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
          break
        }
      }

      bufferedUIEvents = []

      return updates
    }

    return nil
  }
}
