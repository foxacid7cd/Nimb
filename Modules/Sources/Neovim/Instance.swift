// SPDX-License-Identifier: MIT

import CasePaths
import Collections
import Combine
import CustomDump
import Foundation
import Library
import MessagePack

@MainActor
public struct Instance: Sendable {
  public let stateContainer = StateContainer()

  private let process = Foundation.Process()
  private let api: API<ProcessChannel>
  private var apiIterator: API<ProcessChannel>.AsyncIterator?
  private var reportKeyPressesTask: Task<Void, Never>?
  private var reportMouseEventsTask: Task<Void, Never>?

  public init(
    keyPresses: AsyncStream<KeyPress>,
    mouseEvents: AsyncStream<MouseEvent>
  ) {
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

    reportKeyPressesTask = Task {
      for await keyPress in keyPresses {
        guard !Task.isCancelled else {
          return
        }

        do {
          try await api.nvimInputFast(keys: keyPress.makeNvimKeyCode())

        } catch {
          assertionFailure("\(error)")
        }
      }
    }

    reportMouseEventsTask = Task {
      let throttledMouseEvents = mouseEvents
        .throttle(for: .milliseconds(10), latest: true)

      for await mouseEvent in throttledMouseEvents {
        guard !Task.isCancelled else {
          return
        }

        let rawButton: String
        let rawAction: String

        switch mouseEvent.content {
        case let .mouse(button, action):
          rawButton = button.rawValue
          rawAction = action.rawValue

        case let .scrollWheel(direction):
          rawButton = "wheel"
          rawAction = direction.rawValue
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
  }

  @MainActor
  public final class StateContainer: Sendable {
    public private(set) var state = State()

    private var observerBody: ((State.Updates) -> Void)?

    public func apply(uiEvents: [UIEvent]) -> State.Updates? {
      let updates = state.apply(uiEvents: uiEvents)

      if let updates {
        observerBody?(updates)
      }

      return updates
    }

    public func observe(with body: @escaping (State.Updates) -> Void) {
      observerBody = body
    }
  }

  private func attach() async throws {
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
  }
}

extension Instance: AsyncSequence {
  public enum Element: Sendable {
    case stateUpdates(State.Updates)
  }

  public func makeAsyncIterator() -> AsyncIterator {
    .init(
      startProcess: {
        try process.run()
        try await attach()
      },
      stateContainer: stateContainer,
      apiIterator: api.makeAsyncIterator()
    )
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    fileprivate init(
      startProcess: @escaping () async throws -> Void,
      stateContainer: StateContainer,
      apiIterator: API<ProcessChannel>.AsyncIterator
    ) {
      self.startProcess = startProcess
      self.stateContainer = stateContainer
      self.apiIterator = apiIterator
    }

    private let startProcess: () async throws -> Void
    private let stateContainer: StateContainer
    private var apiIterator: API<ProcessChannel>.AsyncIterator
    private var isFirstIteration = true

    public mutating func next() async throws -> Element? {
      if isFirstIteration {
        isFirstIteration = false

        try await startProcess()
      }

      while true {
        guard let uiEvents = try await apiIterator.next() else {
          return nil
        }

        if let updates = await stateContainer.apply(uiEvents: uiEvents) {
          return .stateUpdates(updates)
        }
      }
    }
  }
}
