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

  private var windowController: WindowController?
  private let disposeBag = DisposeBag()
  private var nvimProcess: NvimProcess?
  private var windowControllers = [Int: WindowController]()
  private let glyphRunsCache = Cache<Character, [GlyphRun]>(dispatchQueue: .init(
    label: "\(Bundle.main.bundleIdentifier!).glyphRunsCache",
    attributes: .concurrent
  ))

  private var store: Store {
    .shared
  }

  private func handle(stateChange: StateChange.Grid) {
    switch stateChange.change {
    case .size:
      if self.windowControllers[stateChange.id] == nil {
        let windowController = WindowController(
          gridID: stateChange.id,
          glyphRunsCache: self.glyphRunsCache
        )
        self.windowControllers[stateChange.id] = windowController

        self <~ windowController.charactersPressed
          .bind(with: self) { $0.handlePressed(characters: $1) }

        windowController.showWindow(nil)
      }

    case .destroy:
      if let windowController = self.windowControllers.removeValue(forKey: stateChange.id) {
        windowController.window?.close()

      } else {
        "Trying to destroy unregistered window controller"
          .fail()
          .assertionFailure()
      }

    default:
      break
    }
  }

  private func handlePressed(characters: String) {
    guard let nvimProcess else { return }

    Task {
      do {
        _ = try await nvimProcess.nvimInput(keys: characters)

      } catch {
        "failed nvim input"
          .fail(child: error.fail())
          .assertionFailure()
      }
    }
  }

  @MainActor
  private func startNvimProcess() {
    let nvimProcess = NvimProcess()
    self.nvimProcess = nvimProcess

    nvimProcess.notifications
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] in self?.handle(notification: $0) })
      .disposed(by: self.disposeBag)

    do {
      try nvimProcess.run()

    } catch {
      "failed running nvim process"
        .fail(child: error.fail())
        .log()
    }

    Task {
      do {
        try await nvimProcess.nvimUIAttach(
          width: 160,
          height: 56,
          options: [UIOption.extMultigrid.value: true, UIOption.extHlstate.value: true]
        )
      } catch {
        "failed to attach nvim UI"
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
            self.store.dispatch { state in
              state.grids[model.grid] = CellGrid(
                repeating: nil,
                size: .init(
                  rowsCount: model.height,
                  columnsCount: model.width
                )
              )
              return .grid(.init(
                id: model.grid,
                change: .size
              ))
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
              return .grid(.init(id: model.grid, change: .destroy))
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
                    grid[index] = Cell(
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
                  row: model.bot,
                  column: model.left
                )
                let toOrigin = fromOrigin + GridPoint(row: model.rows, column: 0)
                let fromRectangle = GridRectangle(origin: fromOrigin, size: size)
                let toRectangle = GridRectangle(origin: toOrigin, size: size)
                grid.copy(fromRectangle: fromRectangle, toRectangle: toRectangle)

                stateChanges.append(
                  .grid(.init(
                    id: model.grid,
                    change: .rectangle(toRectangle))
                  )
                )
              }
            }

            return stateChanges
          }

        case let .gridClear(models):
          log(.debug, "Grid clear: \(models.count)")

          for model in models {
            self.store.dispatch { state in
              state.withMutableGrid(id: model.grid) { grid in
                grid = .init(
                  repeating: nil,
                  size: grid.size
                )
              }
              return .grid(.init(id: model.grid, change: .clear))
            }
          }

        case let .gridCursorGoto(models):
          log(.info, "Grid cursor goto: \(models.count)")

        default:
          break
        }
      }
    }
  }
}
