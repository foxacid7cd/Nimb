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
    let nvimExecutablePath = Bundle.main.path(forAuxiliaryExecutable: "nvim")!
    let nvimArguments = ["--embed"]
    let nvimCommand = ([nvimExecutablePath] + nvimArguments)
      .joined(separator: " ")

    let process = Process()
    self.process = process
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

    let stateUpdatesChannel = stateUpdatesChannel
    let newFontChannel = newFontChannel

    task = Task { [weak self] in
      await withThrowingTaskGroup(of: Void.self) { taskGroup in
        taskGroup.addTask { @NeovimActor in
          var bufferedUIEvents = [UIEvent]()

          for try await uiEvents in api {
            guard let self else {
              return
            }
            try Task.checkCancellation()

            bufferedUIEvents += uiEvents

            if let last = uiEvents.last, case .flush = last {
              let stateUpdates = await self.stateContainer.apply(uiEvents: bufferedUIEvents)
              await stateUpdatesChannel.send(stateUpdates)

              if stateUpdates.isCursorUpdated {
                self.resetCursorBlinkingTask()
              }

              bufferedUIEvents = []
            }
          }
        }

        taskGroup.addTask { @NeovimActor in
          try process.run()

          let uiOptions: UIOptions = [
            .extMultigrid,
            .extHlstate,
            .extCmdline,
            .extMessages,
            .extPopupmenu,
            .extTabline,
          ]

          let result = try await api.nvimUIAttach(
            width: initialOuterGridSize.columnsCount,
            height: initialOuterGridSize.rowsCount,
            options: uiOptions.nvimUIAttachOptions
          )
          switch result {
          case .success:
            break
          case let .failure(value):
            throw Failure("failed nvimUIAttach", value)
          }
        }

        while !taskGroup.isEmpty {
          do {
            try await taskGroup.next()
          } catch is CancellationError {
          } catch {
            stateUpdatesChannel.fail(error)
            taskGroup.cancelAll()
          }
        }

        stateUpdatesChannel.finish()
      }
    }

    newFontChannelTask = Task { [weak self] in
      for await newFont in newFontChannel {
        guard let self, !Task.isCancelled else {
          return
        }

        let updates = stateContainer.apply(newFont: newFont)
        await stateUpdatesChannel.send(updates)
      }
    }

    resetCursorBlinkingTask()
  }

  deinit {
    task?.cancel()
    cursorBlinkingTask?.cancel()
    newFontChannelTask?.cancel()
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

  public var state: NeovimState {
    stateContainer.state
  }

  public func set(font: NimsFont) async {
    await newFontChannel.send(font)
  }

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
    try? await api.nvimSelectPopupmenuItemFast(item: index, insert: true, finish: false, opts: [:])
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

  private let stateContainer = NeovimStateContainer()
  private let process: Process
  private let api: API<ProcessChannel>
  private let stateUpdatesChannel = AsyncThrowingChannel<NeovimState.Updates, any Error>()
  private let newFontChannel = AsyncChannel<NimsFont>()
  private var previousMouseMove: (modifier: String?, gridID: Int, point: IntegerPoint)?
  private var task: Task<Void, Never>?
  private var cursorBlinkingTask: Task<Void, Never>?
  private var newFontChannelTask: Task<Void, Never>?

  private func resetCursorBlinkingTask() {
    Task { @NeovimActor in
      cursorBlinkingTask?.cancel()

      if !state.cursorBlinkingPhase {
        stateContainer.set(cursorBlinkingPhase: true)
        await stateUpdatesChannel.send(.init(isCursorBlinkingPhaseUpdated: true))
      }

      if
        state.cmdlines.dictionary.isEmpty,
        let cursorStyle = state.currentCursorStyle,
        let blinkWait = cursorStyle.blinkWait,
        blinkWait > 0,
        let blinkOff = cursorStyle.blinkOff,
        blinkOff > 0,
        let blinkOn = cursorStyle.blinkOn,
        blinkOn > 0
      {
        cursorBlinkingTask = Task { @NeovimActor [weak self] in
          do {
            try await Task.sleep(for: .milliseconds(blinkWait))

            while true {
              guard let self else {
                return
              }

              self.stateContainer.set(cursorBlinkingPhase: false)
              await self.stateUpdatesChannel.send(.init(isCursorBlinkingPhaseUpdated: true))

              try await Task.sleep(for: .milliseconds(blinkOff))

              self.stateContainer.set(cursorBlinkingPhase: true)
              await self.stateUpdatesChannel.send(.init(isCursorBlinkingPhaseUpdated: true))

              try await Task.sleep(for: .milliseconds(blinkOn))
            }
          } catch {}
        }
      }
    }
  }
}

extension Instance: AsyncSequence {
  public typealias Element = NeovimState.Updates

  public nonisolated func makeAsyncIterator() -> AsyncThrowingChannel<NeovimState.Updates, any Error>.AsyncIterator {
    stateUpdatesChannel.makeAsyncIterator()
  }
}
