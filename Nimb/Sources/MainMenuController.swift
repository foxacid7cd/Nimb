// SPDX-License-Identifier: MIT

import AppKit

@MainActor
final class MainMenuController: NSObject {
  init(store: Store) {
    self.store = store
    super.init()

    let appMenu = NSMenu()
    settingsMenuItem.target = self
    appMenu.addItem(settingsMenuItem)
    quitMenuItem.target = self
    appMenu.addItem(quitMenuItem)

    let fileMenu = NSMenu(title: "File")
    openMenuItem.target = self
    fileMenu.addItem(openMenuItem)
    fileMenu.addItem(.separator())
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

    debugMenu.delegate = self

    let windowMenu = NSMenu(title: "Window")
    let helpMenu = NSMenu(title: "Help")

    let submenus = [
      appMenu,
      fileMenu,
      editMenu,
      viewMenu,
      debugMenu,
      windowMenu,
      helpMenu,
    ]

    for submenu in submenus {
      let menuItem = NSMenuItem()
      menuItem.submenu = submenu
      menu.addItem(menuItem)
    }
  }

  let menu = NSMenu()

  var settingsClicked: (@MainActor () -> Void)?

  private let store: Store
  private let settingsMenuItem = NSMenuItem(
    title: "Settings...",
    action: #selector(handleSettings),
    keyEquivalent: ""
  )
  private let quitMenuItem = NSMenuItem(
    title: "Quit Nimb",
    action: #selector(handleQuit),
    keyEquivalent: "q"
  )
  private let openMenuItem = NSMenuItem(
    title: "Open",
    action: #selector(handleOpen),
    keyEquivalent: "o"
  )
  private let saveAsMenuItem = NSMenuItem(
    title: "Save As",
    action: #selector(handleSaveAs),
    keyEquivalent: "s"
  )
  private let closeWindowMenuItem = NSMenuItem(
    title: "Close Window",
    action: #selector(handleCloseWindow),
    keyEquivalent: "w"
  )
  private let editMenu = NSMenu(title: "Edit")
  private let copyItem = NSMenuItem(
    title: "Copy",
    action: #selector(handleCopy),
    keyEquivalent: "c"
  )
  private let pasteItem = NSMenuItem(
    title: "Paste",
    action: #selector(handlePaste),
    keyEquivalent: "v"
  )
  private let viewMenu = NSMenu(title: "View")
  private let debugMenu = NSMenu(title: "Debug")
  private var actionTask: Task<Void, Never>?

  @objc private func handleSettings() {
    settingsClicked?()
  }

  @objc private func handleOpen() {
    guard actionTask == nil else {
      return
    }

    actionTask = Task {
      defer { actionTask = nil }

      let panel = NSOpenPanel()
      panel.canChooseDirectories = true
      panel.showsHiddenFiles = true

      let response = await panel.begin()
      guard !Task.isCancelled, response == .OK, let url = panel.url else {
        return
      }
      await store.edit(url: url)
    }
  }

  @objc private func handleSaveAs() {
    guard actionTask == nil else {
      return
    }

    actionTask = Task {
      defer { actionTask = nil }

      let validBuftypes: Set<String> = ["", "help"]

      guard 
        let (name, buftype) = await store.requestCurrentBufferInfo(),
        validBuftypes.contains(buftype)
      else {
        return
      }

      let panel = NSSavePanel()
      panel.showsHiddenFiles = true
      if name.isEmpty {
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        panel.nameFieldStringValue = "Untitled"
      } else {
        let url = URL(filePath: name)
        panel.directoryURL = url.deletingLastPathComponent()
        panel.nameFieldStringValue = url.lastPathComponent
      }

      let response = await panel.begin()
      guard !Task.isCancelled, response == .OK, let url = panel.url else {
        return
      }
      await store.saveAs(url: url)
    }
  }

  @objc private func handleCloseWindow() {
    guard actionTask == nil else {
      return
    }

    actionTask = Task {
      defer { actionTask = nil }

      await store.close()
    }
  }

  @objc private func handleQuit() {
    guard actionTask == nil else {
      return
    }

    actionTask = Task {
      defer { actionTask = nil }

      await store.quitAll()
    }
  }

  @objc private func handleFont() {
    let fontManager = NSFontManager.shared
    fontManager.target = self
    fontManager.setSelectedFont(store.state.font.appKit(), isMultiple: false)
    fontManager.fontPanel(true)!.makeKeyAndOrderFront(nil)
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
    let currentFont = store.font.appKit()
    let newFontSize = modifier(currentFont.pointSize)
    guard newFontSize != currentFont.pointSize else {
      return
    }
    let newFont = NSFontManager.shared.convert(
      currentFont,
      toSize: newFontSize
    )
    Task {
      await store.set(font: .init(newFont))
    }
  }

  @objc private func handleCopy() {
    guard actionTask == nil else {
      return
    }

    actionTask = Task {
      defer { actionTask = nil }

      guard let text = await store.requestTextForCopy() else {
        return
      }

      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(text, forType: .string)
    }
  }

  @objc private func handlePaste() {
    guard 
      let text = NSPasteboard.general.string(forType: .string),
      actionTask == nil
    else {
      return
    }

    actionTask = Task {
      defer { actionTask = nil }

      store.reportPaste(text: text)
    }
  }

  @objc private func handleToggleUIEventsLogging() {
    Task {
      try await store.dispatch(Actions.ToggleDebugUIEventsLogging())
    }
  }

  @objc private func handleToggleMessagePackInspector() {
    Task {
      try await store.dispatch(Actions.ToggleDebugMessagePackInspector())
    }
  }

  @objc private func handleToggleStoreActionsLogging() {
    Task {
      try await store.dispatch(Actions.ToggleStoreActionsLogging())
    }
  }

  @objc private func handleLogState() {
    Task { @StateActor in
      let dump = store.dumpState()

      let temporaryFileURL = FileManager.default.temporaryDirectory
        .appending(path: "\(UUID().uuidString).txt")
      FileManager.default.createFile(
        atPath: temporaryFileURL.path(),
        contents: nil
      )

      do {
        let fileHandle = try FileHandle(forWritingTo: temporaryFileURL)
        try fileHandle.write(contentsOf: dump.data(using: .utf8)!)
        try fileHandle.close()

        NSWorkspace.shared.open(temporaryFileURL)
      } catch {
        logger
          .error(
            "could not create or write file handle to temporary file with error \(error)"
          )
      }
    }
  }
}

extension OutputStream: TextOutputStream {
  public func write(_ string: String) {
    var string = string

    string.withUTF8 { buffer in
      _ = write(buffer.baseAddress!, maxLength: buffer.count)
    }
  }
}

extension MainMenuController: NSFontChanging {
  func changeFont(_ sender: NSFontManager?) {
    guard let sender else {
      return
    }
    let newFont = sender.convert(store.font.appKit())
    Task {
      await store.set(font: .init(newFont))
    }
  }
}

extension MainMenuController: NSMenuDelegate {
  func menuNeedsUpdate(_ menu: NSMenu) {
    switch menu {
    case viewMenu:
      menu.items = FontMenuLayout.map { item in
        switch item {
        case .currentFontDescription:
          let currentFont = store.font.appKit()
          let name = (currentFont.displayName ?? currentFont.fontName)
            .trimmingCharacters(in: .whitespacesAndNewlines)
          return makeItem("\(name), \(currentFont.pointSize)")

        case .select:
          return makeItem(
            "Select Font",
            action: #selector(handleFont),
            keyEquivalent: "t"
          )

        case .separator:
          return .separator()

        case .increaseSize:
          return makeItem(
            "Increase Font Size",
            action: #selector(handleIncreaseFontSize),
            keyEquivalent: "+"
          )

        case .decreaseSize:
          return makeItem(
            "Decrease Font Size",
            action: #selector(handleDecreaseFontSize),
            keyEquivalent: "-"
          )

        case .resetSize:
          return makeItem(
            "Reset Font Size",
            action: #selector(handleResetFontSize),
            keyEquivalent: "o",
            keyEquivalentModifierMask: [.control, .command]
          )
        }
      }

    case debugMenu:
      let toggleUIEventsLoggingMenuItem = NSMenuItem(
        title: store.state.debug
          .isUIEventsLoggingEnabled ? "Disable UI events logging" :
          "Enable UI events logging",
        action: #selector(handleToggleUIEventsLogging),
        keyEquivalent: ""
      )
      toggleUIEventsLoggingMenuItem.target = self

      let logStateMenuItem = NSMenuItem(
        title: "Log current application state",
        action: #selector(handleLogState),
        keyEquivalent: ""
      )
      logStateMenuItem.target = self

      let toggleMessagePackInspector = NSMenuItem(
        title: store.state.debug
          .isMessagePackInspectorEnabled ? "Disable msgpack data capturing" :
          "Enable msgpack data capturing",
        action: #selector(handleToggleMessagePackInspector),
        keyEquivalent: ""
      )
      toggleMessagePackInspector.target = self

      menu.items = [toggleUIEventsLoggingMenuItem, logStateMenuItem, toggleMessagePackInspector]

      let toggleStoreActionsLoggingMenuItem = NSMenuItem(
        title: store.state.debug
          .isStoreActionsLoggingEnabled ? "Disable store actions logging" :
          "Enable store actions logging",
        action: #selector(handleToggleStoreActionsLogging),
        keyEquivalent: ""
      )
      toggleStoreActionsLoggingMenuItem.target = self

      menu.items = [
        logStateMenuItem,
        NSMenuItem.separator(),
        toggleUIEventsLoggingMenuItem,
        toggleMessagePackInspector,
        toggleStoreActionsLoggingMenuItem,
      ]

    default:
      break
    }
  }

  private func makeItem(
    _ title: String,
    action: Selector? = nil,
    keyEquivalent: String = "",
    keyEquivalentModifierMask: NSEvent.ModifierFlags = [.command]
  )
    -> NSMenuItem
  {
    let item = NSMenuItem(
      title: title,
      action: action,
      keyEquivalent: keyEquivalent
    )
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
