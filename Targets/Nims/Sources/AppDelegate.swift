//
//  AppDelegate.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import CasePaths
import Library
import Nvim
import RxCocoa
import RxSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: AppKit.Notification) {
    self <~ self.store.stateChanges
      .extract { (/StateChange.grid).extract(from: $0) }
      .bind(with: self) { $0.handle(stateChange: $1) }

    self.startNvimProcess()
  }

  @IBOutlet private var mainMenu: NSMenu!

  private let store = Store.shared
  private var gridsWindowController: GridsWindowController?
  private let glyphRunsCache = Cache<Character, [GlyphRun]>(
    dispatchQueue: .init(
      label: "\(Bundle.main.bundleIdentifier!).glyphRunsCache",
      attributes: .concurrent
    )
  )
  private let inputSubject = PublishSubject<KeyPress>()
  private var nvimProcess: NvimProcess?

  @MainActor
  private func handle(stateChange: StateChange.Grid) {
    switch stateChange.change {
    case .size:
      guard self.gridsWindowController == nil else {
        break
      }

      let gridsWindowController = GridsWindowController(glyphRunsCache: self.glyphRunsCache)
      self.gridsWindowController = gridsWindowController

      self <~ gridsWindowController.keyDown
        .map(KeyPress.init)
        .bind(onNext: self.inputSubject.onNext(_:))

      gridsWindowController.showWindow(nil)

    case .windowExternalPosition:
      let gridWindowController = GridWindowController(
        gridID: stateChange.id,
        cellsGeometry: .init(),
        glyphRunsCache: self.glyphRunsCache
      )
      gridWindowController.showWindow(nil)

    default:
      break
    }
  }

  @MainActor
  private func startNvimProcess() {
    let nvimProcess = NvimProcess()
    self.nvimProcess = nvimProcess

    self <~ nvimProcess.notifications
      .observe(on: MainScheduler.instance)
      .bind(with: self) { $0.handle(notification: $1) }

    self <~ self.inputSubject
      .bind(onNext: nvimProcess.input(keyPress:))

    do {
      try nvimProcess.run()

    } catch {
      "Failed running nvim process"
        .fail(child: error.fail())
        .log()
    }

    Task {
      do {
        try await nvimProcess.nvimUIAttach(
          width: self.store.state.outerGridSize.columnsCount,
          height: self.store.state.outerGridSize.rowsCount,
          options: [
            UIOption.extMultigrid.value: true,
            UIOption.extHlstate.value: true,
            UIOption.extMessages.value: true
          ]
        )
      } catch {
        "Failed to attach nvim UI"
          .fail(child: error.fail())
          .assertionFailure()
      }
    }
  }

  @MainActor
  private func handle(notification: NvimNotification) {
    switch notification {
    case let .redraw(uiEvents):
      for uiEvent in uiEvents {
        switch uiEvent {
        case let .gridResize(models):
          log(.info, "Grid resize: \(models.count)")

          for model in models {
            log(.info, "grid resize: \(model)")

            self.store.dispatch { state in
              let size = GridSize(
                rowsCount: model.height,
                columnsCount: model.width
              )
              state.grids[model.grid] = State.Grid(
                window: nil,
                grid: CellGrid(
                  repeating: nil,
                  size: size
                )
              )

              return [
                .grid(.init(
                  id: model.grid,
                  change: .size
                ))
              ]
            }
          }

        case let .gridDestroy(models):
          log(.info, "Grid destroy: \(models.count)")

          for model in models {
            self.store.dispatch { state in
              if state.grids[model.grid] == nil {
                "Trying to destroy unexisting grid"
                  .fail()
                  .assertionFailure()
              }

              state.grids[model.grid] = nil

              return [
                .grid(.init(
                  id: model.grid,
                  change: .destroy
                ))
              ]
            }
          }

        case let .gridLine(models):
          log(.info, "Grid line: \(models.count)")

          self.store.dispatch { state in
            var stateChanges = [StateChange]()
            var latestHlID: Int?
            var latestRow: Int?

            for model in models {
              state.withMutableGrid(id: model.grid) { grid in
                var updatedCellsCount = 0
                for messagePackValue in model.data {
                  guard var arrayValue = messagePackValue.arrayValue else {
                    "cell data is not an array"
                      .fail()
                      .assertionFailure()

                    continue
                  }

                  guard !arrayValue.isEmpty, let text = arrayValue.removeFirst().stringValue else {
                    "expected cell text is not a string"
                      .fail()
                      .assertionFailure()

                    continue
                  }
                  let character = text.first

                  var repeatCount = 1

                  if !arrayValue.isEmpty {
                    guard let hlID = arrayValue.removeFirst().uintValue else {
                      "expected cell hl_id is not an unsigned integer"
                        .fail()
                        .assertionFailure()

                      continue
                    }
                    latestHlID = Int(hlID)

                    if !arrayValue.isEmpty {
                      guard let parsedRepeatCount = arrayValue.removeFirst().uintValue else {
                        "expected cell repeat count is not an unsigned integer"
                          .fail()
                          .assertionFailure()

                        continue
                      }
                      repeatCount = Int(parsedRepeatCount)
                    }
                  }

                  guard let latestHlID else {
                    "at least one hlID had to be parsed"
                      .fail()
                      .assertionFailure()

                    continue
                  }

                  if latestRow != model.row {
                    updatedCellsCount = 0
                  }

                  for repeatIndex in 0 ..< repeatCount {
                    let index = GridPoint(
                      row: model.row,
                      column: model.colStart + updatedCellsCount + repeatIndex
                    )
                    grid!.grid[index] = Cell(
                      character: character,
                      hlID: latestHlID
                    )
                  }

                  stateChanges.append(
                    .grid(.init(
                      id: model.grid,
                      change: .row(.init(
                        origin: .init(
                          row: model.row,
                          column: model.colStart + updatedCellsCount
                        ),
                        columnsCount: repeatCount
                      ))
                    ))
                  )

                  updatedCellsCount += repeatCount

                  latestRow = model.row
                }
              }
            }

            return stateChanges
          }

        case let .gridScroll(models):
          log(.info, "Grid scroll: \(models.count)")

          self.store.dispatch { state in
            var stateChanges = [StateChange]()

            for model in models {
              state.withMutableGrid(id: model.grid) { grid in
                let size = GridSize(
                  rowsCount: model.bot - model.top,
                  columnsCount: model.right - model.left
                )

                let fromOrigin = GridPoint(
                  row: model.top,
                  column: model.left
                )

                let rectangle = grid!.grid.move(
                  rectangle: .init(origin: fromOrigin, size: size),
                  delta: .init(row: model.rows, column: model.cols)
                )

                stateChanges.append(
                  .grid(.init(
                    id: model.grid,
                    change: .rectangle(rectangle)
                  ))
                )
              }
            }

            return stateChanges
          }

        case let .gridClear(models):
          log(.info, "Grid clear: \(models.count)")

          for model in models {
            self.store.dispatch { state in
              state.withMutableGrid(id: model.grid) { grid in
                grid!.grid = .init(
                  repeating: nil,
                  size: grid!.grid.size
                )
              }

              return [
                .grid(.init(
                  id: model.grid,
                  change: .clear
                ))
              ]
            }
          }

        case let .gridCursorGoto(models):
          log(.info, "Grid cursor goto: \(models.count)")

          self.store.dispatch { state in
            var stateChanges = [StateChange]()

            for model in models {
              if let previousCursor = state.cursor {
                stateChanges.append(
                  .cursor(previousCursor)
                )
              }

              let cursor = State.Cursor(
                gridID: model.grid,
                index: .init(
                  row: model.row,
                  column: model.col
                )
              )
              state.cursor = cursor

              stateChanges.append(.cursor(cursor))
            }

            return stateChanges
          }

        case let .winPos(models):
          log(.info, "Win pos: \(models.count)")

          self.store.dispatch { state in
            var stateChanges = [StateChange]()

            for model in models {
              log(.info, "win pos: \(model)")

              state.withMutableGrid(id: model.grid) { grid in
                grid!.window = .init(
                  native: model.win,
                  frame: .init(
                    origin: .init(
                      row: model.startrow,
                      column: model.startcol
                    ),
                    size: .init(
                      rowsCount: model.height,
                      columnsCount: model.width
                    )
                  ),
                  isHidden: false
                )

                let frame = grid!.window!.frame
                log(.info, "win pos window frame: \(frame)")

                stateChanges.append(
                  .grid(.init(
                    id: model.grid,
                    change: .windowPosition
                  ))
                )
              }
            }

            return stateChanges
          }

        case let .winFloatPos(models):
          log(.info, "Win float pos: \(models.count)")

//          self.store.dispatch { state in
//            var stateChanges = [StateChange]()
//
//            for model in models {
//              state.withMutableGrid(id: model.grid) { grid in
//                model.anchorGrid
//              }
//            }
//
//            return stateChanges
//          }

        case let .winExternalPos(models):
          log(.info, "Win external pos: \(models.count)")

          self.store.dispatch { state in
            var stateChanges = [StateChange]()

            for model in models {
              state.withMutableGrid(id: model.grid) { grid in
                grid!.window = .init(
                  native: model.win,
                  frame: .init(
                    origin: .init(),
                    size: grid!.grid.size
                  ),
                  isHidden: false
                )

                stateChanges.append(
                  .grid(.init(
                    id: model.grid,
                    change: .windowExternalPosition
                  ))
                )
              }
            }

            return stateChanges
          }

        case let .winHide(models):
          log(.info, "Win hide: \(models.count)")

          self.store.dispatch { state in
            var stateChanges = [StateChange]()

            for model in models {
              state.withMutableGrid(id: model.grid) { grid in
                grid!.window!.isHidden = true

                stateChanges.append(
                  .grid(.init(
                    id: model.grid,
                    change: .windowHide
                  ))
                )
              }
            }

            return stateChanges
          }

        case let .winClose(models):
          log(.info, "Win close: \(models.count)")

          self.store.dispatch { state in
            var stateChanges = [StateChange]()

            for model in models {
              state.withMutableGrid(id: model.grid) { grid in
                grid?.window = nil

                stateChanges.append(
                  .grid(.init(
                    id: model.grid,
                    change: .windowClose
                  ))
                )
              }
            }

            return stateChanges
          }

        default:
          break
        }
      }
    }
  }
}
