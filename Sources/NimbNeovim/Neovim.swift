// SPDX-License-Identifier: MIT

import Foundation
import NimbCore
import Synchronization

public final class Neovim: Sendable {
  @PublicInit
  public struct Termination: Sendable {
    public enum Reason: String, Sendable {
      case exit
      case uncaughtSignal
    }

    public var status: Int32
    public var reason: Reason
    public var standardError: String
  }

  private final class Launch: @unchecked Sendable {
    let process: Process
    let standardError: StandardErrorBuffer

    init(process: Process, standardError: StandardErrorBuffer) {
      self.process = process
      self.standardError = standardError
    }
  }

  private final class StandardErrorBuffer: Sendable {
    private let data = Mutex(Data())

    var string: String {
      data.withLock { String(decoding: $0, as: UTF8.self) }
    }

    func append(_ newData: Data) {
      data.withLock { buffer in
        buffer.append(newData)
        if buffer.count > 65536 {
          buffer.removeFirst(buffer.count - 65536)
        }
      }
    }
  }

  public let api: API

  private let isReattaching = Mutex(false)

  private let launch: Mutex<Launch>

  public init() {
    let launch = Self.makeLaunch()
    self.launch = .init(launch)
    api = .init(RPC(ProcessChannel(launch.process)))
  }

  private static func makeLaunch() -> Launch {
    let process = Process()

    var environment = UserDefaults.standard.environmentOverlay
    // percentEncoded: false, because this is a filesystem path and not a URL
    // component, and a path with a space would otherwise arrive with %20.
    environment["VIMRUNTIME"] = Bundle.main.resourceURL!
      .appending(path: "nvim")
      .appending(path: "runtime")
      .absoluteURL
      .path(percentEncoded: false)
      .replacing(/\/$/, with: "")
    // Paths travel in the environment, so a space or quote cannot rewrite the
    // command. The login shell picks up PATH; exec avoids a parent process.
    guard let nvimExecutablePath = Bundle.main.path(forAuxiliaryExecutable: "nvim") else {
      preconditionFailure(
        "nvim is missing from the app bundle; run 'make neovim' and rebuild",
      )
    }
    environment["NIMB_NVIM_EXECUTABLE"] = nvimExecutablePath

    var vimrcArgument = ""
    switch UserDefaults.standard.vimrc {
    case .default:
      break
    case .norc:
      vimrcArgument = " -u NORC"
    case .none:
      vimrcArgument = " -u NONE"
    case let .custom(url):
      // Same reason as above: the path is passed through, not spliced in.
      environment["NIMB_NVIM_VIMRC"] = url.path(percentEncoded: false)
      vimrcArgument = " -u \"$NIMB_NVIM_VIMRC\""
    }

    process.environment = environment

    let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    process.executableURL = URL(filePath: shell)
    process.arguments = [
      "-l",
      "-c",
      "exec \"$NIMB_NVIM_EXECUTABLE\" --embed" + vimrcArgument,
    ]

    process.currentDirectoryURL = FileManager.default
      .homeDirectoryForCurrentUser

    let standardError = StandardErrorBuffer()
    let standardErrorPipe = Pipe()
    process.standardError = standardErrorPipe

    standardErrorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
      let data = fileHandle.availableData
      guard !data.isEmpty else {
        return
      }
      standardError.append(data)
    }

    return .init(process: process, standardError: standardError)
  }

  public func bootstrap() async throws -> Termination {
    try await run(launch.withLock { $0 })
  }

  public func restart(outerGridSize: IntegerSize? = nil) async throws -> Termination {
    let newLaunch = Self.makeLaunch()
    launch.withLock { $0 = newLaunch }
    api.rpc.reconnect(to: ProcessChannel(newLaunch.process))
    return try await run(newLaunch, outerGridSize: outerGridSize)
  }

  public func reattach(to address: String, outerGridSize: IntegerSize? = nil) async throws {
    do {
      try api.rpc.reconnect(to: SocketChannel(path: address))
      try await sendClientInfo()
      try await attachUI(outerGridSize: outerGridSize)
    } catch {
      isReattaching.withLock { $0 = false }
      throw error
    }
  }

  public func prepareForReattach() {
    isReattaching.withLock { $0 = true }
  }

  public func consumeExpectedProcessExit() -> Bool {
    isReattaching.withLock { value in
      defer { value = false }
      return value
    }
  }

  private func run(_ launch: Launch, outerGridSize: IntegerSize? = nil) async throws -> Termination {
    let process = launch.process
    let (terminations, continuation) = AsyncStream<Int32>.makeStream()
    process.terminationHandler = { process in
      continuation.yield(process.terminationStatus)
      continuation.finish()
    }
    try process.run()

    do {
      let version = Bundle.main.version ?? (0, 0, 0)
      try await api.nvimSetClientInfo(
        name: "Nimb",
        version: [
          "major": .integer(version.major),
          "minor": .integer(version.minor),
          "patch": .integer(version.patch),
          "prerelease": "dev",
        ],
        type: "ui",
        methods: ["nimb_notify": .dictionary([
          "async": true,
          "nargs": .integer(3),
        ])],
        attributes: [:],
      )

      let initLua = try String(
        contentsOf: Bundle.main.resourceURL!
          .appending(path: "nvim")
          .appending(path: "init.lua"),
        encoding: .utf8,
      )
      try await api.nvimExecLua(code: initLua, args: [])
      try await attachUI(outerGridSize: outerGridSize)
    } catch {
      if process.isRunning {
        process.terminate()
        _ = await terminations.first(where: { _ in true })
      }
      process.terminationHandler = nil
      throw error
    }

    let status = await terminations.first(where: { _ in true }) ?? process.terminationStatus
    process.terminationHandler = nil
    let reason: Termination.Reason = process.terminationReason == .exit ? .exit : .uncaughtSignal
    let standardError = launch.standardError.string
    return .init(status: status, reason: reason, standardError: standardError)
  }

  private func sendClientInfo() async throws {
    let version = Bundle.main.version ?? (0, 0, 0)
    try await api.nvimSetClientInfo(
      name: "Nimb",
      version: [
        "major": .integer(version.major),
        "minor": .integer(version.minor),
        "patch": .integer(version.patch),
        "prerelease": "dev",
      ],
      type: "ui",
      methods: ["nimb_notify": .dictionary([
        "async": true,
        "nargs": .integer(3),
      ])],
      attributes: [:],
    )
  }

  private func attachUI(outerGridSize: IntegerSize? = nil) async throws {
    let uiOptions: UIOptions = [
      .extMultigrid,
      .extHlstate,
      .extTabline,
    ]
    let outerGridSize = outerGridSize ?? UserDefaults.standard.savedWindowGeometry?.outerGridSize
      ?? .init(columnsCount: 110, rowsCount: 34)
    try await api.nvimUIAttach(
      width: outerGridSize.columnsCount,
      height: outerGridSize.rowsCount,
      options: uiOptions.nvimUIAttachOptions,
    )
  }
}
