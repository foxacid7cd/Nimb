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

  private let process = Foundation.Process()
  private let api: API<ProcessChannel>
  private var observers = [UUID: @MainActor (State.Updates) -> Void]()
  private var reportMouseEventsTask: Task<Void, Never>?
  private var task: Task<Error?, Never>?
  private var mouseEventsChannel = AsyncChannel<MouseEvent>()

  public init() {
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
            gridID: mouseEvent.gridID,
            row: mouseEvent.point.row,
            col: mouseEvent.point.column
          )
        } catch {
          assertionFailure("\(error)")
        }
      }
    }

    task = Task {
      do {
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
          width: 190,
          height: 64,
          options: uiOptions.nvimUIAttachOptions
        )

        for try await uiEvents in api {
          if let stateUpdates = state.apply(uiEvents: uiEvents) {
            for (_, body) in observers {
              body(stateUpdates)
            }
          }
        }

        return nil

      } catch {
        return error
      }
    }
  }

  deinit {
    reportMouseEventsTask?.cancel()
  }

  public func stateUpdatesStream() -> AsyncStream<State.Updates> {
    .init(bufferingPolicy: .unbounded) { [weak self] continuation in
      let id = UUID()

      self?.observers[id] = { newValue in
        continuation.yield(newValue)
      }

      continuation.onTermination = { _ in
        Task { @MainActor in
          self?.observers.removeValue(forKey: id)
        }
      }
    }
  }

  public func finishedResult() async -> Error? {
    await task!.value
  }

  public func report(keyPress: KeyPress) async {
    do {
      let keys = keyPress.makeNvimKeyCode()
      _ = try await api.nvimInputFast(keys: keys)

    } catch {
      assertionFailure("\(error)")
    }
  }

  public func report(mouseEvent: MouseEvent) async {
    await mouseEventsChannel.send(mouseEvent)
  }

  public func reportPumBounds(gridFrame: CGRect) async {
    try? await api.nvimUIPumSetBoundsFast(
      width: gridFrame.width,
      height: gridFrame.height,
      row: gridFrame.origin.y,
      col: gridFrame.origin.x
    )
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
}
