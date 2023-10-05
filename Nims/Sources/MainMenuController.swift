// SPDX-License-Identifier: MIT

import AppKit

@MainActor
final class MainMenuController: NSObject {
  init(store: Store) {
    self.store = store

    super.init()

    let appMenu = NSMenu()
    let fileMenu = NSMenu(title: "File")
    let editMenu = NSMenu(title: "Edit")
    copyItem.target = self
    editMenu.addItem(copyItem)
    pasteItem.target = self
    editMenu.addItem(pasteItem)
    let formatMenu = NSMenu(title: "Format")
    let viewMenu = NSMenu(title: "View")
    let windowMenu = NSMenu(title: "Window")
    let helpMenu = NSMenu(title: "Help")

    let submenus = [appMenu, fileMenu, editMenu, formatMenu, viewMenu, windowMenu, helpMenu]

    for submenu in submenus {
      let menuItem = NSMenuItem()
      menuItem.submenu = submenu
      menu.addItem(menuItem)
    }
  }

  let menu = NSMenu()

  func render(_: State.Updates) {}

  private let store: Store
  private let editMenu = NSMenu(title: "Edit")
  private let copyItem = NSMenuItem(title: "Copy", action: #selector(handleCopy), keyEquivalent: "c")
  private let pasteItem = NSMenuItem(title: "Paste", action: #selector(handlePaste), keyEquivalent: "v")

  @objc private func handleCopy() {
    Task {
      await store.instance.reportCopy()
    }
  }

  @objc private func handlePaste() {
    guard let text = NSPasteboard.general.string(forType: .string) else {
      return
    }

    Task {
      await store.instance.reportPaste(text: text)
    }
  }
}
