// SPDX-License-Identifier: MIT

import AppKit
import CustomDump

@MainActor
final class MainMenuController: NSObject {
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
  private let saveMenuItem = NSMenuItem(
    title: "Save",
    action: #selector(handleSave),
    keyEquivalent: "s"
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
    saveMenuItem.target = self
    saveMenuItem.keyEquivalentModifierMask = [.command]
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

    //    viewMenu.delegate = self
    //
    //    debugMenu.delegate = self

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

  func render() { }

  @objc private func handleSettings() {
    settingsClicked?()
  }

  @objc private func handleOpen() {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.showsHiddenFiles = true
    switch panel.runModal() {
    case .OK:
      if let url = panel.url {
        store.apiTask {
          try await $0.nimb(method: "edit", parameters: [.string(url.path())])
        }
      }

    default:
      break
    }
  }

  @objc private func handleSave() {
    store.apiTask {
      _ = try await $0.nimb(method: "write")
    }
  }

  @objc private func handleSaveAs() {
    Task {
      let validBuftypes: Set<String> = ["", "help"]

      guard let buf = await getCurrentBufferInfo(), validBuftypes.contains(buf.type) else {
        return
      }

      let panel = NSSavePanel()
      panel.showsHiddenFiles = true
      panel.runModal()
      let name2 = panel.nameFieldStringValue
      if name2.isEmpty {
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        panel.nameFieldStringValue = "Untitled"
      } else {
        let url = URL(filePath: "panel")
        panel.directoryURL = url.deletingLastPathComponent()
        panel.nameFieldStringValue = url.lastPathComponent
        store.apiTask {
          _ = try await $0.nimb(method: "save_as", parameters: [.string(url.path())])
        }
      }
    }
  }

  private func getCurrentBufferInfo() async -> (name: String, type: String)? {
    await store.apiAsyncTask { api in
      async let name = api.nvimBufGetName(bufferID: .current)
      async let rawBuftype = api.nvimGetOptionValue(
        name: "buftype",
        opts: ["buf": .integer(0)]
      )
      do {
        return try await (
          name: name,
          type: rawBuftype[case: \.string] ?? ""
        )
      }
    }
  }

  @objc private func handleCloseWindow() {
    store.apiTask {
      try await $0.nimb(method: "close")
    }
  }

  @objc private func handleQuit() {
    store.apiTask {
      try await $0.nimb(method: "quit_all")
    }
  }

  @objc private func handleFont() {
    let fontManager = NSFontManager.shared
    fontManager.target = self
    //    fontManager.setSelectedFont(state.font.appKit(), isMultiple: false)
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

  private func changeFontSize(_: (_ fontSize: Double) -> Double) {
    //    let currentFont = state.font.appKit()
    //    let newFontSize = modifier(currentFont.pointSize)
    //    guard newFontSize != currentFont.pointSize else {
    //      return
    //    }
    //    let newFont = NSFontManager.shared.convert(
    //      currentFont,
    //      toSize: newFontSize
    //    )
    //    store.dispatch(Actions.SetFont(value: Font(newFont)))
  }

  @objc private func handleCopy() {
    Task {
      guard let text = await requestTextForCopy() else {
        return
      }

      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(text, forType: .string)
    }
  }

  @objc private func handlePaste() {
    guard
      let text = NSPasteboard.general.string(forType: .string)
    else {
      return
    }

    store.apiTask {
      try await $0.nvimPaste(data: text, crlf: false, phase: -1)
    }
  }

  @objc private func handleToggleUIEventsLogging() {
    store.dispatch(Actions.ToggleDebugUIEventsLogging())
  }

  @objc private func handleToggleMessagePackInspector() {
    store.dispatch(Actions.ToggleDebugMessagePackInspector())
  }

  @objc private func handleToggleStoreActionsLogging() {
    store.dispatch(Actions.ToggleStoreActionsLogging())
  }

  @objc private func handleLogState() {
    //    Task { @MainActor in
    //      var dump = ""
    //      customDump(self.state, to: &dump, maxDepth: 10)
    //
    //      let temporaryFileURL = FileManager.default.temporaryDirectory
    //        .appending(path: "Nimb_state_dump_\(UUID().uuidString).txt")
    //      FileManager.default.createFile(
    //        atPath: temporaryFileURL.path(),
    //        contents: nil
    //      )
    //
    //      do {
    //        let fileHandle = try FileHandle(forWritingTo: temporaryFileURL)
    //        try fileHandle.write(contentsOf: dump.data(using: .utf8)!)
    //        try fileHandle.close()
    //
    //        NSWorkspace.shared.open(temporaryFileURL)
    //      } catch {
    //        logger
    //          .error(
    //            "could not create or write file handle to temporary file with error \(error)"
    //          )
    //      }
    //    }
  }

  private func requestTextForCopy() async -> String? {
    nil
    //    guard
    //      let mode = state.mode,
    //      let modeInfo = state.modeInfo
    //    else {
    //      return nil
    //    }
    //
    //    let shortName = modeInfo.cursorStyles[mode.cursorStyleIndex].shortName
    //    let firstCharacter = shortName?.lowercased().first
    //    if ["i", "n", "o", "r", "s", "v"].contains(firstCharacter) {
    //      return await store.apiAsyncTask { api in
    //        let rawSuccess = try await api.nimb(method: "buf_text_for_copy")
    //        guard let text = rawSuccess.flatMap(\.string) else {
    //          throw Failure("success result is not a string", rawSuccess as Any)
    //        }
    //        return text
    //      }
    //    } else if firstCharacter == "c" {
    //      if
    //        let lastCmdlineLevel = state.cmdlines.lastCmdlineLevel,
    //        let cmdline = state.cmdlines.dictionary[lastCmdlineLevel]
    //      {
    //        return cmdline.contentParts
    //          .map { _ in "" }
    //          .joined()
    //      }
    //    }
    //
    //    return nil
    //  }
  }
}

extension OutputStream: @retroactive TextOutputStream {
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
//    let newFont = sender.convert(state.font.appKit())
//    store.dispatch(Actions.SetFont(value: .init(newFont)))
  }
}

extension MainMenuController: NSMenuDelegate {
  func menuNeedsUpdate(_: NSMenu) {
//    guard isRendered else {
//      return
//    }
//    switch menu {
//    case viewMenu:
//      menu.items = fontMenuLayout.map { item in
//        switch item {
//        case .currentFontDescription:
//          let currentFont = state.font.appKit()
//          let name = (currentFont.displayName ?? currentFont.fontName)
//            .trimmingCharacters(in: .whitespacesAndNewlines)
//          return makeItem("\(name), \(currentFont.pointSize)")
//
//        case .select:
//          return makeItem(
//            "Select Font",
//            action: #selector(handleFont),
//            keyEquivalent: "t"
//          )
//
//        case .separator:
//          return .separator()
//
//        case .increaseSize:
//          return makeItem(
//            "Increase Font Size",
//            action: #selector(handleIncreaseFontSize),
//            keyEquivalent: "+"
//          )
//
//        case .decreaseSize:
//          return makeItem(
//            "Decrease Font Size",
//            action: #selector(handleDecreaseFontSize),
//            keyEquivalent: "-"
//          )
//
//        case .resetSize:
//          return makeItem(
//            "Reset Font Size",
//            action: #selector(handleResetFontSize),
//            keyEquivalent: "o",
//            keyEquivalentModifierMask: [.control, .command]
//          )
//        }
//      }
//
//    case debugMenu:
//      let toggleUIEventsLoggingMenuItem = NSMenuItem(
//        title: state.debug
//          .isUIEventsLoggingEnabled ? "Disable UI events logging" :
//          "Enable UI events logging",
//        action: #selector(handleToggleUIEventsLogging),
//        keyEquivalent: ""
//      )
//      toggleUIEventsLoggingMenuItem.target = self
//
//      let logStateMenuItem = NSMenuItem(
//        title: "Dump current application state",
//        action: #selector(handleLogState),
//        keyEquivalent: ""
//      )
//      logStateMenuItem.target = self
//
//      let toggleMessagePackInspector = NSMenuItem(
//        title: state.debug
//          .isMessagePackInspectorEnabled ? "Disable msgpack data capturing" :
//          "Enable msgpack data capturing",
//        action: #selector(handleToggleMessagePackInspector),
//        keyEquivalent: ""
//      )
//      toggleMessagePackInspector.target = self
//
//      let toggleStoreActionsLoggingMenuItem = NSMenuItem(
//        title: state.debug
//          .isStoreActionsLoggingEnabled ? "Disable store actions logging" :
//          "Enable store actions logging",
//        action: #selector(handleToggleStoreActionsLogging),
//        keyEquivalent: ""
//      )
//      toggleStoreActionsLoggingMenuItem.target = self
//
//      menu.items = [
//        logStateMenuItem,
//        NSMenuItem.separator(),
//        toggleUIEventsLoggingMenuItem,
//        toggleMessagePackInspector,
//        toggleStoreActionsLoggingMenuItem,
//      ]
//
//    default:
//      break
//    }
  }

  private func makeItem(
    _ title: String,
    action: Selector? = nil,
    keyEquivalent: String = "",
    keyEquivalentModifierMask: NSEvent.ModifierFlags = [.command]
  )
  -> NSMenuItem {
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

private let fontMenuLayout: [FontMenuItem] = [
  .currentFontDescription,
  .select,
  .separator,
  .increaseSize,
  .decreaseSize,
  .resetSize,
]
