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
  private let store = Store()

  @MainActor
  func applicationDidFinishLaunching(_: AppKit.Notification) {
    let menubar = NSMenu()
    let appMenuItem = NSMenuItem()
    menubar.addItem(appMenuItem)

    NSApp.mainMenu = menubar

    let appMenu = NSMenu()
    let appName = ProcessInfo.processInfo.processName

    let quitTitle = "Quit \(appName)"

    let quitMenuItem = NSMenuItem(
      title: quitTitle,
      action: #selector(NSApplication.shared.terminate(_:)),
      keyEquivalent: "q"
    )
    appMenu.addItem(quitMenuItem)
    appMenuItem.submenu = appMenu

    let window = Window(store: store)
    window.title = appName
    window.makeMain()
    window.makeKeyAndOrderFront(nil)

    let client = Client()

    Task {
      for try await notification in client {
        switch notification {
        case let .redraw(uiEvents):
          for uiEvent in uiEvents {
            switch uiEvent {
            case let .gridResize(models):
              store.dispatch { state in
                for model in models {
                  state.grids[model.grid] = .init(id: model.grid, width: model.width, height: model.height)
                  if state.currentGridID == nil {
                    state.currentGridID = model.grid
                  }
                }
              }

            case let .gridDestroy(models):
              store.dispatch { state in
                for model in models {
                  if state.currentGridID == model.grid {
                    state.currentGridID = nil
                  }
                  let removedGrid = state.grids.removeValue(forKey: model.grid)
                  if removedGrid == nil {
                    "tried to remove unexisting grid".fail().failAssertion()
                  }
                }
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
        try await client.nvimUIAttach(width: 90, height: 32, options: [.string(UIOption.extMultigrid.rawValue): true, .string(UIOption.extHlstate.rawValue): true])
      } catch {
        "failed to attach nvim UI".fail(child: error.fail()).failAssertion()
      }
    }
  }
}
