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

    viewMenu.delegate = self

    let windowMenu = NSMenu(title: "Window")
    let helpMenu = NSMenu(title: "Help")

    let submenus = [appMenu, fileMenu, editMenu, viewMenu, windowMenu, helpMenu]

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
  private let viewMenu = NSMenu(title: "View")

  @objc private func handleFont() {
    let fontManager = NSFontManager.shared
    fontManager.target = self
    fontManager.fontPanel(true)!.makeKeyAndOrderFront(nil)

    fontManager.setSelectedFont(store.font.nsFont(), isMultiple: false)
  }

  @objc private func handleIncreaseFontSize() {
    changeFontSize { min(60, $0 + 1) }
  }

  @objc private func handleDecreaseFontSize() {
    changeFontSize { max(7, $0 - 1) }
  }

  @objc private func handleResetFontSize() {
    changeFontSize { _ in NSFont.systemFontSize }
  }

  private func changeFontSize(_ modifier: (_ fontSize: Double) -> Double) {
    let currentFont = store.font.nsFont()
    let newFontSize = modifier(currentFont.pointSize)
    guard newFontSize != currentFont.pointSize else {
      return
    }
    let newFont = NSFontManager.shared.convert(
      currentFont,
      toSize: newFontSize
    )
    store.set(font: .init(newFont))
    UserDefaults.standard.setValue(newFontSize, forKey: "fontSize")
  }

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

extension MainMenuController: NSFontChanging {
  func changeFont(_ sender: NSFontManager?) {
    guard let sender else {
      return
    }

    let newFont = sender.convert(store.font.nsFont())
    store.set(font: .init(newFont))

    UserDefaults.standard.setValue(newFont.fontName, forKey: "fontName")
    UserDefaults.standard.setValue(newFont.pointSize, forKey: "fontSize")
  }
}

extension MainMenuController: NSMenuDelegate {
  func menuNeedsUpdate(_ menu: NSMenu) {
    menu.items = FontMenuLayout.map { item in
      switch item {
      case .currentFontDescription:
        let currentFont = store.font.nsFont()
        let name = (currentFont.displayName ?? currentFont.fontName)
          .trimmingCharacters(in: .whitespacesAndNewlines)
        return makeItem("\(name), \(currentFont.pointSize)")

      case .select:
        return makeItem("Select Font", action: #selector(handleFont), keyEquivalent: "t")

      case .separator:
        return .separator()

      case .increaseSize:
        return makeItem("Increase Font Size", action: #selector(handleIncreaseFontSize), keyEquivalent: "+")

      case .decreaseSize:
        return makeItem("Decrease Font Size", action: #selector(handleDecreaseFontSize), keyEquivalent: "-")

      case .resetSize:
        return makeItem("Reset Font Size", action: #selector(handleResetFontSize), keyEquivalent: "o", keyEquivalentModifierMask: [.control, .command])
      }
    }
  }

  private func makeItem(_ title: String, action: Selector? = nil, keyEquivalent: String = "", keyEquivalentModifierMask: NSEvent.ModifierFlags = [.command]) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
    item.target = self
    item.keyEquivalentModifierMask = keyEquivalentModifierMask
    return item
  }
}

private enum FontMenuItem {
  case currentFontDescription
  case select
  case separator
  case increaseSize
  case decreaseSize
  case resetSize
}

private let FontMenuLayout: [FontMenuItem] = [
  .currentFontDescription,
  .select,
  .separator,
  .increaseSize,
  .decreaseSize,
  .resetSize,
]