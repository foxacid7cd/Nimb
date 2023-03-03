// SPDX-License-Identifier: MIT

import CasePaths
import Collections
import Combine
import CustomDump
import Foundation
import Library
import MessagePack

public struct Instance {
  public let stateContainer = StateContainer()

  private let process = Foundation.Process()
  private let api: API<ProcessChannel>
  private var apiIterator: API<ProcessChannel>.AsyncIterator?

  public init() {
    let nvimExecutableURL = Bundle.main.url(forAuxiliaryExecutable: "nvim")!
    let nvimArguments = ["--embed"]
    let nvimCommand = ([nvimExecutableURL.relativePath] + nvimArguments)
      .joined(separator: " ")

    process.executableURL = URL(filePath: "/bin/zsh")
    process.arguments = ["-l", "-c", nvimCommand]

    let environmentOverlay = [String: String]()

    var environment = ProcessInfo.processInfo.environment
    environment["VIMRUNTIME"] = "/opt/homebrew/share/nvim/runtime"
    environment.merge(environmentOverlay, uniquingKeysWith: { $1 })
    process.environment = environment

    let processChannel = ProcessChannel(process)
    let rpc = RPC(processChannel)
    api = .init(rpc)
  }

  public actor StateContainer: Sendable {
    public private(set) var state = State()

    private var observerBody: ((State.Updates) -> Void)?

    public func apply(uiEvents: [UIEvent]) -> State.Updates {
      let updates = state.apply(uiEvents: uiEvents)
      observerBody?(updates)

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
  public enum Element {
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

      guard let uiEvents = try await apiIterator.next() else {
        return nil
      }

      return .stateUpdates(
        await stateContainer.apply(uiEvents: uiEvents)
      )
    }
  }
}
