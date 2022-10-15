//
//  AppDelegate.swift
//
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//

import API
import AppKit
import Library
import MessagePack

class AppDelegate: NSObject, NSApplicationDelegate {
  var client: Client?

  func applicationDidFinishLaunching(_: Notification) {
    let client = Client()
    self.client = client

    Task {
      for try await notification in client {
        switch notification {
        case let .redraw(uiEvents):
          for uiEvent in uiEvents {
            String(describing: uiEvent).fail().log()
          }
        }
      }
    }

    Task {
      do {
        try await client.nvimUIAttach(width: 80, height: 24, options: [.string(UIOption.extMultigrid.rawValue): true, .string(UIOption.extHlstate.rawValue): true])
      } catch {
        "nvim UI attach failed".fail(child: error.fail()).fatal()
      }
    }
  }
}

//  var client: Client?
//
//  @MainActor func applicationDidFinishLaunching(_: AppKit.Notification) {
//    let menubar = NSMenu()
//    let appMenuItem = NSMenuItem()
//    menubar.addItem(appMenuItem)
//
//    NSApp.mainMenu = menubar
//
//    let appMenu = NSMenu()
//    let appName = ProcessInfo.processInfo.processName
//
//    let quitTitle = "Quit \(appName)"
//
//    let quitMenuItem = NSMenuItem(
//      title: quitTitle,
//      action: #selector(NSApplication.shared.terminate(_:)),
//      keyEquivalent: "q"
//    )
//    appMenu.addItem(quitMenuItem)
//    appMenuItem.submenu = appMenu
//
//    let window = NSWindow(
//      contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
//      styleMask: [.titled, .closable, .miniaturizable, .resizable],
//      backing: .buffered,
//      defer: false
//    )
//    window.center()
//    window.title = appName
//    window.makeKeyAndOrderFront(nil)
//
//    let client = Client()
//    self.client = client
//
//    Task {
//      for try await notification in client {
//        switch notification {
//        case let .redraw(uiEvents):
//          for uiEvent in uiEvents {
//            log(.debug, String(describing: uiEvent))
//          }
//        }
//      }
//    }
//
//    Task {
//      do {
//        try await client.nvimUIAttach(width: 80, height: 24, options: [.string(UIOption.extMultigrid.rawValue: true])
//      } catch let errorValue as MessagePackValue {
//        fatalError("nvim error \(errorValue)")
//
//      } catch {
//        fatalError("unknown error \(error)")
//      }
//    }
//  }
// }
