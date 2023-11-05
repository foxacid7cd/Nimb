// SPDX-License-Identifier: MIT

import AppKit

@MainActor
final class MainMenuController: NSObject {
  init(store: Store) {
    self.store = store
    super.init()

    let appMenu = NSMenu()
    quitMenuItem.target = self
    appMenu.addItem(quitMenuItem)

    let fileMenu = NSMenu(title: "File")
    openMenuItem.target = self
    fileMenu.addItem(openMenuItem)
    fileMenu.addItem(.separator())
    saveMenuItem.target = self
    fileMenu.addItem(saveMenuItem)
    saveAsMenuItem.target = self
    saveAsMenuItem.keyEquivalentModifierMask = [.shift, .command]
    fileMenu.addItem(saveAsMenuItem)
    fileMenu.addItem(.separator())
    closeWindowMenuItem.target = self
    fileMenu.addItem(closeWindowMenuItem)

    let editMenu = NSMenu(title: "Edit")
    copyItem.target = self
    editMenu.addItem(copyItem)
    pasteItem.target = self
    editMenu.addItem(pasteItem)

    viewMenu.delegate = self

    let windowMenu = NSMenu(title: "Window")
    let helpMenu = NSMenu(title: "Help")

    var submenus = [appMenu, fileMenu, editMenu, viewMenu, windowMenu, helpMenu]

    #if DEBUG
      debugMenu.delegate = self
      submenus.insert(debugMenu, at: submenus.count - 2)
    #endif

    for submenu in submenus {
      let menuItem = NSMenuItem()
      menuItem.submenu = submenu
      menu.addItem(menuItem)
    }
  }

  let menu = NSMenu()

  private let store: Store
  private let quitMenuItem = NSMenuItem(title: "Quit Nims", action: #selector(handleQuit), keyEquivalent: "q")
  private let openMenuItem = NSMenuItem(title: "Open", action: #selector(handleOpen), keyEquivalent: "o")
  private let saveMenuItem = NSMenuItem(title: "Save", action: #selector(handleSave), keyEquivalent: "s")
  private let saveAsMenuItem = NSMenuItem(title: "Save As", action: #selector(handleSaveAs), keyEquivalent: "s")
  private let closeWindowMenuItem = NSMenuItem(title: "Close Window", action: #selector(handleCloseWindow), keyEquivalent: "w")
  private let editMenu = NSMenu(title: "Edit")
  private let copyItem = NSMenuItem(title: "Copy", action: #selector(handleCopy), keyEquivalent: "c")
  private let pasteItem = NSMenuItem(title: "Paste", action: #selector(handlePaste), keyEquivalent: "v")
  private let viewMenu = NSMenu(title: "View")
  private let debugMenu = NSMenu(title: "Debug")

  @objc private func handleOpen() {
    let panel = NSOpenPanel()
    panel.showsHiddenFiles = true
    panel.canChooseDirectories = true

    if panel.runModal() == .OK, let url = panel.url {
      store.edit(url: url)
    }
  }

  @objc private func handleSave() {
    store.write()
  }

  @objc private func handleSaveAs() {
    let panel = NSSavePanel()
    panel.showsHiddenFiles = true

    if panel.runModal() == .OK, let url = panel.url {
      store.saveAs(url: url)
    }
  }

  @objc private func handleCloseWindow() {
    store.quit()
  }

  @objc private func handleQuit() {
    store.quitAll()
  }

  @objc private func handleFont() {
    let selectedFont = store.state.font.nsFont()

    let fontManager = NSFontManager.shared
    fontManager.target = self
    fontManager.fontPanel(true)!.makeKeyAndOrderFront(nil)

    fontManager.setSelectedFont(selectedFont, isMultiple: false)
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
      if let text = await store.requestTextForCopy() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
      }
    }
  }

  @objc private func handlePaste() {
    guard let text = NSPasteboard.general.string(forType: .string) else {
      return
    }

    store.reportPaste(text: text)
  }

  @objc private func handleToggleUIEventsLogging() {
    store.toggleUIEventsLogging()
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
    switch menu {
    case viewMenu:
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

    case debugMenu:
      let title = store.state.debug.isUIEventsLoggingEnabled ? "Disable UI events logging" : "Enable UI events logging"
      let item = NSMenuItem(title: title, action: #selector(handleToggleUIEventsLogging), keyEquivalent: "")
      item.target = self
      menu.items = [item]

    default:
      break
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
