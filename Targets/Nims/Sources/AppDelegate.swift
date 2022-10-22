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

  private var store: Store {
    .shared
  }

  private func handle(stateChange: StateChange.Grid) {
    switch stateChange.change {
    case .size:
      if self.windowControllers[stateChange.id] == nil {
        let windowController = WindowController(gridID: stateChange.id)
        self.windowControllers[stateChange.id] = windowController
        windowController.showWindow(nil)
      }

    case .destroy:
      if let windowController = self.windowControllers[stateChange.id] {
        windowController.window?.close()
        self.windowControllers[stateChange.id] = nil

      } else {
        "Trying to destroy unregistered window controller"
          .fail()
          .assertionFailure()
      }

    default:
      break
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
          width: 110,
          height: 40,
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
              return .grid(
                .init(
                  id: model.grid,
                  change: .size
                )
              )
            }
          }

        case let .gridDestroy(models):
          log(.info, "Grid destroy: \(models.count)")

          for model in models {
            self.store.dispatch { state in
              if state.grids[model.grid] == nil {
                log(.fault, "Trying destroy unexisting grid")
              }

              state.grids[model.grid] = nil
              return .grid(.init(id: model.grid, change: .destroy))
            }
          }

        case let .gridLine(models):
          log(.info, "Grid line: \(models.count)")

          self.store.dispatch { (state: inout State) -> [StateChange] in
            var stateChanges = [StateChange]()
            var latestHlID: Int?
            var latestRow: Int?

            for model in models {
              var updatedCellsCount = 0
              for messagePackValue in model.data {
                guard var arrayValue = messagePackValue.arrayValue else {
                  "cell data is not an array"
                    .fail()
                    .log(.fault)

                  continue
                }

                guard !arrayValue.isEmpty, let text = arrayValue.removeFirst().stringValue else {
                  "expected cell text is not a string"
                    .fail()
                    .log(.fault)

                  continue
                }

                var repeatCount = 1

                if !arrayValue.isEmpty {
                  guard let hlID = arrayValue.removeFirst().uintValue else {
                    "expected cell hl_id is not an unsigned integer"
                      .fail()
                      .log(.fault)

                    continue
                  }
                  latestHlID = Int(hlID)

                  if !arrayValue.isEmpty {
                    guard let parsedRepeatCount = arrayValue.removeFirst().uintValue else {
                      "expected cell repeat count is not an unsigned integer"
                        .fail()
                        .log(.fault)

                      continue
                    }
                    repeatCount = Int(parsedRepeatCount)
                  }
                }

                guard let latestHlID else {
                  "at least one hlID had to be parsed"
                    .fail()
                    .log(.fault)

                  continue
                }

                if latestRow != model.row {
                  updatedCellsCount = 0
                }

                for _ in 0 ..< repeatCount {
                  let index = GridPoint(
                    row: model.row,
                    column: model.colStart + updatedCellsCount
                  )
                  state.grids[model.grid]![index] = Cell(text: text, hlID: latestHlID)

                  updatedCellsCount += 1
                }

                stateChanges.append(
                  .grid(
                    .init(
                      id: model.grid,
                      change: .row(
                        .init(
                          origin: .init(
                            row: model.row,
                            column: model.colStart + updatedCellsCount - repeatCount
                          ),
                          columnsCount: repeatCount
                        )
                      )
                    )
                  )
                )

                latestRow = model.row
              }
            }

            return stateChanges
          }

        case let .gridScroll(models):
          log(.debug, "Grid scroll: \(models.count)")

          for model in models {
            self.store.dispatch { state in
              let rectangle = GridRectangle(
                origin: .init(row: model.top, column: model.left),
                size: .init(rowsCount: model.bot - model.top, columnsCount: model.right - model.left)
              )
              state.grids[model.grid]!.set(
                state.grids[model.grid]!.grid(
                  at: rectangle
                ),
                at: .init(
                  row: rectangle.origin.row + model.rows,
                  column: rectangle.origin.column + model.cols
                )
              )

              return nil
            }
          }

        case let .gridClear(models):
          log(.debug, "Grid clear: \(models.count)")

          for model in models {
            self.store.dispatch { state in
              state.grids[model.grid]! = .init(
                repeating: nil,
                size: state.grids[model.grid]!.size
              )
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
