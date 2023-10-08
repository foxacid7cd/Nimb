// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import CasePaths
import Collections
import CustomDump
import Foundation
import Library
import MessagePack

@MainActor
public final class Instance: Sendable {
  public init(neovimRuntimeURL: URL, initialOuterGridSize: IntegerSize) {
    let nvimExecutablePath = Bundle.main.path(forAuxiliaryExecutable: "nvim")!
    let nvimArguments = ["--embed"]
    let nvimCommand = ([nvimExecutablePath] + nvimArguments)
      .joined(separator: " ")

    process.executableURL = URL(filePath: "/bin/zsh")
    process.arguments = ["-l", "-c", nvimCommand]
    process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser

    let environmentOverlay: [String: String] = [
      "VIMRUNTIME": neovimRuntimeURL.standardizedFileURL.path(),
    ]

    var environment = ProcessInfo.processInfo.environment
    environment.merge(environmentOverlay, uniquingKeysWith: { $1 })
    process.environment = environment

    let processChannel = ProcessChannel(process)
    let rpc = RPC(processChannel)
    let api = API(rpc)

    self.api = api

    task = .init {
      try process.run()

      let uiOptions: UIOptions = [
        .extMultigrid,
        .extHlstate,
        .extCmdline,
        .extMessages,
        .extPopupmenu,
        .extTabline,
      ]

      try await api.nvimUIAttachFast(
        width: initialOuterGridSize.columnsCount,
        height: initialOuterGridSize.rowsCount,
        options: uiOptions.nvimUIAttachOptions
      )

      for try await uiEvents in api {
        if let stateUpdates = state.apply(uiEvents: uiEvents) {
          for (_, body) in self.observers {
            body(stateUpdates)
          }
        }
      }
    }
  }

  public private(set) var state = NeovimState()

  public var result: Result<Void, Error> {
    get async {
      await task!.result
    }
  }

  public func stateUpdatesStream() -> AsyncStream<NeovimState.Updates> {
    .init { [weak self] continuation in
      let id = UUID()

      self?.observers[id] = { updates in
        continuation.yield(updates)
      }

      continuation.onTermination = { _ in
        Task { @MainActor in
          self?.observers.removeValue(forKey: id)
        }
      }
    }
  }

  public func report(keyPress: KeyPress) async {
    let keys = keyPress.makeNvimKeyCode()
    try? await api.nvimInputFast(keys: keys)
  }

  public func report(mouseEvents: [MouseEvent]) async {
    let calls = mouseEvents
      .map { mouseEvent -> (method: String, parameters: [Value]) in
        let (rawButton, rawAction) = switch mouseEvent.content {
        case let .mouseButton(button, action):
          (button.rawValue, action.rawValue)

        case .mouseMove:
          ("move", "")

        case let .scrollWheel(direction):
          ("wheel", direction.rawValue)
        }

        return (
          method: "nvim_input_mouse",
          parameters: [.string(rawButton), .string(rawAction), .string(mouseEvent.modifier), .integer(mouseEvent.gridID), .integer(mouseEvent.point.row), .integer(mouseEvent.point.column)]
        )
      }

    try? await api.rpc.fastCallsTransaction(with: calls)
  }

  public func reportPopupmenuItemSelected(atIndex index: Int) async {
    try? await api.nvimSelectPopupmenuItemFast(item: index, insert: false, finish: false, opts: [:])
  }

  public func reportTablineBufferSelected(withID id: Buffer.ID) async {
    try? await api.nvimSetCurrentBufFast(bufferID: id)
  }

  public func reportTablineTabpageSelected(withID id: Tabpage.ID) async {
    try? await api.nvimSetCurrentTabpageFast(tabpageID: id)
  }

  public func report(gridWithID id: Grid.ID, changedSizeTo size: IntegerSize) async {
    try? await api.nvimUITryResizeGridFast(
      grid: id,
      width: size.columnsCount,
      height: size.rowsCount
    )
  }

  public func reportPumBounds(gridFrame: CGRect) async {
    try? await api.nvimUIPumSetBoundsFast(
      width: gridFrame.width,
      height: gridFrame.height,
      row: gridFrame.origin.y,
      col: gridFrame.origin.x
    )
  }

  public func reportPaste(text: String) async {
    try? await api.nvimPasteFast(data: text, crlf: false, phase: -1)
  }

  public func reportCopy() async -> String? {
    guard let mode = state.mode, let modeInfo = state.modeInfo else {
      return nil
    }

    let shortName = modeInfo.cursorStyles[mode.cursorStyleIndex].shortName

    switch shortName?.lowercased().first {
    case "i",
         "n",
         "o",
         "r",
         "s",
         "v":
      do {
        return try await api.nvimExecLua(
          code: "return require('nims').buf_text_for_copy()",
          args: []
        )
        .map(/Value.string)

      } catch {
        assertionFailure(error)
        return nil
      }

    case "c":
      if let lastCmdlineLevel = state.cmdlines.lastCmdlineLevel, let cmdline = state.cmdlines.dictionary[lastCmdlineLevel] {
        return cmdline.contentParts
          .map(\.text)
          .joined()
      }

    default:
      break
    }

    return nil
  }

  private let process = Foundation.Process()
  private let api: API<ProcessChannel>
  private var observers = [UUID: @MainActor (NeovimState.Updates) -> Void]()
  private var task: Task<Void, Error>?
}
