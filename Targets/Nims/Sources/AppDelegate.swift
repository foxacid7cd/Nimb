//
//  AppDelegate.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Library
import Nvim
import RxSwift

@NSApplicationMain @MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: AppKit.Notification) {
    self.startNvimProcess()

    let windowController = WindowController()
    self.windowController = windowController
    windowController.showWindow(nil)
  }

  @IBOutlet private var mainMenu: NSMenu!

  private var windowController: WindowController?
  private let disposeBag = DisposeBag()
  private var nvimProcess: NvimProcess?

  @MainActor
  private func startNvimProcess() {
    let nvimProcess = NvimProcess()
    self.nvimProcess = nvimProcess

    nvimProcess.notifications
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
          width: 90,
          height: 32,
          options: [.string(UIOption.extMultigrid.rawValue): true, .string(UIOption.extHlstate.rawValue): true]
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
          Store.shared.mutateState { state in
            var notifications = [Store.Notification]()

            for model in models {
              let grid = Library.Grid<State.Cell?>(
                repeating: nil,
                rowsCount: model.height,
                columnsCount: model.width
              )
              state.grids[model.grid] = grid
              notifications.append(.gridCreated(id: model.grid))

              if state.currentGridID == nil {
                state.currentGridID = model.grid
                notifications.append(.currentGridChanged)
              }
            }

            return models.map { .gridCreated(id: $0.grid) }
          }

        case let .gridDestroy(models):
          Store.shared.mutateState { state in
            var notifications = [Store.Notification]()

            for model in models {
              guard state.grids[model.grid] != nil else {
                "grid_destroy for unexisting grid".fail().assertionFailure()
                continue
              }
              state.grids.removeValue(forKey: model.grid)
              notifications.append(.gridDestroyed(id: model.grid))

              if state.currentGridID == model.grid {
                state.currentGridID = state.grids.keys.first
                notifications.append(.currentGridChanged)
              }
            }

            return notifications
          }

        case let .gridLine(models):
          Store.shared.mutateState { state in
            var notifications = [Store.Notification]()

            var lastHlID: Int?
            for model in models {
              guard var grid = state.grids[model.grid] else {
                "unexisting grid".fail().assertionFailure()
                continue
              }

              var updatedCellsCount = 0
              for messagePackValue in model.data {
                guard var arrayValue = messagePackValue.arrayValue else {
                  "cell data is not an array".fail().assertionFailure()
                  continue
                }

                guard !arrayValue.isEmpty, let text = arrayValue.removeFirst().stringValue else {
                  "expected cell text is not a string".fail().assertionFailure()
                  continue
                }

                var repeatCount = 1

                if !arrayValue.isEmpty {
                  guard let hlID = arrayValue.removeFirst().uintValue else {
                    "expected cell hl_id is not an unsigned integer".fail().assertionFailure()
                    continue
                  }
                  lastHlID = Int(hlID)

                  if !arrayValue.isEmpty {
                    guard let parsedRepeatCount = arrayValue.removeFirst().uintValue else {
                      "expected cell repeat count is not an unsigned integer".fail().assertionFailure()
                      continue
                    }
                    repeatCount = Int(parsedRepeatCount)
                  }
                }

                guard let lastHlID else {
                  "at least one hlID was expected to be parsed".fail().assertionFailure()
                  continue
                }

                for repeatIndex in 0 ..< repeatCount {
                  let row = model.row
                  let column = model.colStart + Int(repeatIndex)
                  guard row < grid.columnsCount else {
                    break
                  }
                  grid[.init(row: row, column: column)] = .init(character: text.first, hlID: lastHlID)

                  updatedCellsCount += 1
                }
              }

              state.grids[model.grid] = grid

              notifications.append(
                .gridUpdated(
                  id: model.grid,
                  updates: .line(
                    row: model.row,
                    columnStart: model.colStart,
                    cellsCount: updatedCellsCount
                  )
                )
              )
            }

            return notifications
          }

        default:
          continue
        }
      }
    }
  }
}
