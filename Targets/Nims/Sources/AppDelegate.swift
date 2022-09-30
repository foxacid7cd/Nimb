//
//  AppDelegate.swift
//
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//

import AppKit
import Conversations

class AppDelegate: NSObject, NSApplicationDelegate {
  var nvim: MessagingProcess?

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

    let nvim = MessagingProcess(
      executableURL: URL(fileURLWithPath: "/bin/zsh"),
      arguments: ["-c", "nvim --embed"]
    )
    self.nvim = nvim

    Task {
      do {
        for try await event in nvim {
          print(event)
        }
      } catch {
        log(.error, "Error: \(error)")
      }
    }
  }
}
