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
  private var task: Task<Error?, Never>?

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
          width: 200,
          height: 60,
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

  public func stateUpdatesStream() -> AsyncStream<State.Updates> {
    .init(bufferingPolicy: .bufferingNewest(1)) { continuation in
      let id = UUID()

      observers[id] = { newValue in
        continuation.yield(newValue)
      }

      continuation.onTermination = { _ in
        Task { @MainActor in
          self.observers.removeValue(forKey: id)
        }
      }
    }
  }

  public func finishedResult() async -> Error? {
    await task!.value
  }

  public func report(keyPress: KeyPress) async {
    do {
      _ = try await api.nvimInput(
        keys: keyPress.makeNvimKeyCode()
      )

    } catch {
      assertionFailure("\(error)")
    }
  }

  public func report(mouseEvent: MouseEvent) async {
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
