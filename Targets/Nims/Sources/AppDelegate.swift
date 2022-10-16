//
//  AppDelegate.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import AsyncAlgorithms
import Library
import MessagePack
import Neovim
import RxSwift

class AppDelegate: NSObject, NSApplicationDelegate {
  @MainActor
  func applicationDidFinishLaunching(_: AppKit.Notification) {
    self.setupMenu()
    self.startNvimProcess()

    self.window.title = ProcessInfo.processInfo.processName
    self.window.setContentSize(.init(width: 1280, height: 960))
    self.window.makeMain()
    self.window.orderFront(nil)
  }

  private lazy var store = Store()
  private lazy var window = Window(store: store)
  private let disposeBag = DisposeBag()

  @MainActor
  private func setupMenu() {
    let menubar = NSMenu()
    let appMenuItem = NSMenuItem()
    menubar.addItem(appMenuItem)
    NSApp.mainMenu = menubar

    let appMenu = NSMenu()
    let quitTitle = "Quit \(ProcessInfo.processInfo.processName)"
    let quitMenuItem = NSMenuItem(
      title: quitTitle,
      action: #selector(NSApplication.shared.terminate(_:)),
      keyEquivalent: "q"
    )

    appMenu.addItem(quitMenuItem)
    appMenuItem.submenu = appMenu
  }

  @MainActor
  private func startNvimProcess() {
    let process = NvimProcess()

    process.notifications
      .subscribe(onNext: { [weak self] in self?.handle(notification: $0) })
      .disposed(by: self.disposeBag)

    Task {
      do {
        try await process.nvimUIAttach(
          width: 90,
          height: 32,
          options: [.string(UIOption.extMultigrid.rawValue): true, .string(UIOption.extHlstate.rawValue): true]
        )
      } catch {
        "failed to attach nvim UI".fail(child: error.fail()).failAssertion()
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
          self.store.mutateState { state in
            var notifications = [Store.Notification]()

            for model in models {
              let grid = Library.Grid<Store.Cell?>(
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
          self.store.mutateState { state in
            var notifications = [Store.Notification]()

            for model in models {
              guard state.grids[model.grid] != nil else {
                "grid_destroy for unexisting grid".fail().failAssertion()
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
          self.store.mutateState { state in
            var notifications = [Store.Notification]()

            var lastHlID: Int?
            for model in models {
              guard var grid = state.grids[model.grid] else {
                "unexisting grid".fail().failAssertion()
                continue
              }

              var updatedCellsCount = 0
              for messagePackValue in model.data {
                guard var arrayValue = messagePackValue.arrayValue else {
                  "cell data is not an array".fail().failAssertion()
                  continue
                }

                guard !arrayValue.isEmpty, let text = arrayValue.removeFirst().stringValue else {
                  "expected cell text is not a string".fail().failAssertion()
                  continue
                }

                var repeatCount = 1

                if !arrayValue.isEmpty {
                  guard let hlID = arrayValue.removeFirst().uintValue else {
                    "expected cell hl_id is not an unsigned integer".fail().failAssertion()
                    continue
                  }
                  lastHlID = Int(hlID)

                  if !arrayValue.isEmpty {
                    guard let parsedRepeatCount = arrayValue.removeFirst().uintValue else {
                      "expected cell repeat count is not an unsigned integer".fail().failAssertion()
                      continue
                    }
                    repeatCount = Int(parsedRepeatCount)
                  }
                }

                guard let lastHlID else {
                  "at least one hlID was expected to be parsed".fail().failAssertion()
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
