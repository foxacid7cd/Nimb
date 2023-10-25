// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import CasePaths
import Collections
import CustomDump
import Foundation
import Library
import MessagePack

@NeovimActor
public final class Instance: Sendable {
  public init(neovimRuntimeURL: URL, initialOuterGridSize: IntegerSize) {
    self.initialOuterGridSize = initialOuterGridSize
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
  }

  public enum MouseButton: String, Sendable {
    case left
    case right
    case middle
  }

  public enum MouseAction: String, Sendable {
    case press
    case drag
    case release
  }

  public enum ScrollDirection: String, Sendable {
    case up
    case down
    case left
    case right
  }

  public private(set) var state = NeovimState()

  public func report(keyPress: KeyPress) async {
    let keys = keyPress.makeNvimKeyCode()
    try? await api.nvimInputFast(keys: keys)
  }

  public nonisolated func reportMouseMove(modifier: String?, gridID: Grid.ID, point: IntegerPoint) {
    Task { @NeovimActor in
      do {
        if
          let previousMouseMove,
          previousMouseMove.modifier == modifier,
          previousMouseMove.gridID == gridID,
          previousMouseMove.point == point
        {
          return
        }

        previousMouseMove = (modifier, gridID, point)

        try await api.nvimInputMouseFast(
          button: "move",
          action: "",
          modifier: modifier ?? "",
          grid: gridID,
          row: point.row,
          col: point.column
        )
      } catch {
        assertionFailure(error)
      }
    }
  }

  public nonisolated func reportScrollWheel(with direction: ScrollDirection, modifier: String?, gridID: Grid.ID, point: IntegerPoint, count: Int) {
    Task { @NeovimActor in
      do {
        try await api.rpc.fastCallsTransaction(
          with: Array(
            repeating: (
              method: "nvim_input_mouse",
              parameters: [
                .string("wheel"),
                .string(direction.rawValue),
                .string(modifier ?? ""),
                .integer(gridID),
                .integer(point.row),
                .integer(point.column),
              ]
            ),
            count: count
          )
        )
      } catch {
        assertionFailure(error)
      }
    }
  }

  public nonisolated func report(mouseButton: MouseButton, action: MouseAction, modifier: String?, gridID: Grid.ID, point: IntegerPoint) {
    Task { @NeovimActor in
      do {
        try await api.nvimInputMouseFast(
          button: mouseButton.rawValue,
          action: action.rawValue,
          modifier: modifier ?? "",
          grid: gridID,
          row: point.row,
          col: point.column
        )
      } catch {
        assertionFailure(error)
      }
    }
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

  private let initialOuterGridSize: IntegerSize
  private let process = Foundation.Process()
  private let api: API<ProcessChannel>
  private var observers = [UUID: @NeovimActor (NeovimState.Updates) -> Void]()
  private var previousMouseMove: (modifier: String?, gridID: Int, point: IntegerPoint)?

  @NeovimActor
  private func apply(uiEvents: [UIEvent]) -> NeovimState.Updates? {
    state.apply(uiEvents: uiEvents)
  }

  @NeovimActor
  private func runAndAttach() async throws {
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
  }
}

extension Instance: AsyncSequence {
  public typealias Element = NeovimState.Updates

  public nonisolated func makeAsyncIterator() -> AsyncIterator {
    .init(instance: self, apiIterator: api.makeAsyncIterator())
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    fileprivate init(instance: Instance, apiIterator: API<ProcessChannel>.AsyncIterator) {
      self.instance = instance
      self.apiIterator = apiIterator
    }

    public mutating func next() async throws -> NeovimState.Updates? {
      if !isProcessRunning {
        isProcessRunning = true

        try await instance.runAndAttach()
      }

      while true {
        if let uiEvents = try await apiIterator.next() {
          if let stateUpdates = await instance.apply(uiEvents: uiEvents) {
            return stateUpdates
          }

        } else {
          return nil
        }
      }
    }

    private let instance: Instance
    private var apiIterator: API<ProcessChannel>.AsyncIterator
    private var isProcessRunning = false
  }
}
