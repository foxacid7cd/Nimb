//
//  AppDelegate.swift
//
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//

import API
import AppKit
import MessagePack

class AppDelegate: NSObject, NSApplicationDelegate {
  var client: Client?

  @MainActor func applicationDidFinishLaunching(_: Notification) {
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

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.center()
    window.title = appName
    window.makeKeyAndOrderFront(nil)

    let client = Client()
    self.client = client

    Task {
      do {
        for try await event in client {
          print(event)
        }
      } catch {
        log(.error, "Error: \(error)")
      }
    }

    Task {
      do {
        try await client.nvimUiAttach(width: 120, height: 80, options: ["ext_multigrid": true])
      } catch let errorValue as MessagePackValue {
        print(errorValue)

      } catch {
        fatalError("Unknown error: \(error)")
      }
    }
  }
}
