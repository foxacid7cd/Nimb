// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import CasePaths
import Collections
import CustomDump
import Foundation
import Library
import MessagePack

@StateActor
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

    task = Task { [uiEventsChannel] in
      await withThrowingTaskGroup(of: Void.self) { taskGroup in
        taskGroup.addTask { @StateActor in
          for try await uiEvents in api {
            try Task.checkCancellation()

            await uiEventsChannel.send(uiEvents)
          }
        }

        taskGroup.addTask { @StateActor in
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
            taskGroup.cancelAll()
            uiEventsChannel.fail(error)
          }
        }

        uiEventsChannel.finish()
      }
    }
  }

  deinit {
    task?.cancel()
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

  public func report(keyPress: KeyPress) async {
    let keys = keyPress.makeNvimKeyCode()
    try? await api.nvimInputFast(keys: keys)
  }

  public nonisolated func reportMouseMove(modifier: String?, gridID: Grid.ID, point: IntegerPoint) {
    Task { @StateActor in
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
    Task { @StateActor in
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
    Task { @StateActor in
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

  public func bufTextForCopy() async -> String? {
    try? await api.nvimExecLua(
      code: "return require('nims').buf_text_for_copy()",
      args: []
    )
    .map(/Value.string)
  }

  private let process: Process
  private let api: API<ProcessChannel>
  private let uiEventsChannel = AsyncThrowingChannel<[UIEvent], any Error>()
  private var previousMouseMove: (modifier: String?, gridID: Int, point: IntegerPoint)?
  private var task: Task<Void, Never>?
}

extension Instance: AsyncSequence {
  public typealias Element = [UIEvent]

  public nonisolated func makeAsyncIterator() -> AsyncThrowingChannel<[UIEvent], any Error>.AsyncIterator {
    uiEventsChannel.makeAsyncIterator()
  }
}
