//
//  AppDelegate.swift
//
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//

import AppKit
import MessagePack

class AppDelegate: NSObject, NSApplicationDelegate {
  var nvimInstance: NvimInstance?

  func applicationDidFinishLaunching(_: Notification) {
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

    Task.detached { [weak self] in
      do {
        let nvimInstance = try await NvimInstance(
          executableURL: URL(fileURLWithPath: "/opt/homebrew/bin/nvim")
        )
        self?.nvimInstance = nvimInstance
        try await nvimInstance.client.nvimUiAttach(width: 80, height: 24, options: .map([:]))
        for try await event in await nvimInstance.events {
          log(.debug, "Received event \(event).")
        }
      } catch {
        log(.error, "Failed starting nvim instance, \(error).")
      }
    }
  }
}
