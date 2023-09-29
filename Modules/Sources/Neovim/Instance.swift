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
  public private(set) var state = State()

  public var result: Result<Void, Error> {
    get async {
      await task!.result
    }
  }

  private let process = Foundation.Process()
  private let api: API<ProcessChannel>
  private var observers = [UUID: @MainActor (State.Updates) -> Void]()
  private var reportMouseEventsTask: Task<Void, Never>?
  private var task: Task<Void, Error>?
  private let mouseEventsChannel = AsyncChannel<MouseEvent>()

  public init(initialOuterGridSize: IntegerSize) {
    let nvimExecutablePath = Bundle.main.path(forAuxiliaryExecutable: "nvim")!
    let nvimArguments = ["--embed"]
    let nvimCommand = ([nvimExecutablePath] + nvimArguments)
      .joined(separator: " ")

    process.executableURL = URL(filePath: "/bin/zsh")
    process.arguments = ["-l", "-c", nvimCommand]

    let environmentOverlay = [String: String]()

    var environment = ProcessInfo.processInfo.environment
    environment.merge(environmentOverlay, uniquingKeysWith: { $1 })
    process.environment = environment

    let processChannel = ProcessChannel(process)
    let rpc = RPC(processChannel)
    let api = API(rpc)

    self.api = api

    reportMouseEventsTask = Task {
      for await mouseEvent in mouseEventsChannel._throttle(for: .milliseconds(10), latest: true) {
        guard !Task.isCancelled else {
          return
        }

        let (rawButton, rawAction) = switch mouseEvent.content {
        case let .mouse(button, action):
          (button.rawValue, action.rawValue)

        case let .scrollWheel(direction):
          ("wheel", direction.rawValue)
        }

        do {
          try await api.nvimInputMouseFast(
            button: rawButton,
            action: rawAction,
            modifier: "",
            grid: mouseEvent.gridID,
            row: mouseEvent.point.row,
            col: mouseEvent.point.column
          )
        } catch {
          assertionFailure(error)
        }
      }
    }

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

  public func stateUpdatesStream() -> AsyncStream<State.Updates> {
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

  public func report(mouseEvent: MouseEvent) async {
    await mouseEventsChannel.send(mouseEvent)
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
}
