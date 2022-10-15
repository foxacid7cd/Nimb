//
//  AppDelegate.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import API
import AppKit
import AsyncAlgorithms
import Library
import MessagePack
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
  @MainActor
  func applicationDidFinishLaunching(_: AppKit.Notification) {
    self.setupMenu()
    self.runClient()

    self.window.title = ProcessInfo.processInfo.processName
    self.window.makeMain()
    self.window.makeKeyAndOrderFront(nil)
  }

  private lazy var store = Store()
  private lazy var window = Window(store: store)

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
  private func runClient() {
    let client = Client()

    Task {
      for try await notification in client {
        switch notification {
        case let .redraw(uiEvents):
          for uiEvent in uiEvents {
            switch uiEvent {
            case let .gridResize(models):
              store.mutateState { state in
                for model in models {
                  let grid = Library.Grid<Cell?>(
                    repeating: nil,
                    rowsCount: model.height,
                    columnsCount: model.width
                  )
                  state.grids[model.grid] = grid
                }

                return models.map { .gridCreated(id: $0.grid) }
              }

            case let .gridDestroy(models):
              store.mutateState { state in
                for model in models {
                  guard state.grids[model.grid] != nil else {
                    "grid_destroy for unexisting grid".fail().failAssertion()
                    continue
                  }
                  state.grids[model.grid] = nil
                }

                return models.map { .gridDestroyed(id: $0.grid) }
              }

            case let .gridLine(models):
              store.mutateState { state in
                var notifications = [Store.Notification]()

                var lastHlID: UInt?
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

                    guard !arrayValue.isEmpty, let string = arrayValue.removeFirst().stringValue else {
                      "expected cell text is not a string".fail().failAssertion()
                      continue
                    }

                    var repeatCount = 1

                    if !arrayValue.isEmpty {
                      guard let hlID = arrayValue.removeFirst().uintValue else {
                        "expected cell hl_id is not an unsigned integer".fail().failAssertion()
                        continue
                      }
                      lastHlID = hlID

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

                    let character = string.first

                    for repeatIndex in 0 ..< repeatCount {
                      grid[.init(row: model.row, column: model.colStart + Int(repeatIndex))] =
                        .init(character: character, hlID: lastHlID)

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

    Task {
      do {
        try await client.nvimUIAttach(
          width: 90,
          height: 32,
          options: [.string(UIOption.extMultigrid.rawValue): true, .string(UIOption.extHlstate.rawValue): true]
        )
      } catch {
        "failed to attach nvim UI".fail(child: error.fail()).failAssertion()
      }
    }
  }
}
