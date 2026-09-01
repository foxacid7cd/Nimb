// SPDX-License-Identifier: MIT

import Foundation
import NimbCore
import Synchronization

public final class Neovim: Sendable {
  public let process: Process
  public let api: API

  /// While set, the process exiting is expected rather than a reason to quit.
  public let isReattaching = Mutex(false)

  public init() {
    process = Process()

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

    let standardErrorPipe = Pipe()
    process.standardError = standardErrorPipe

    standardErrorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
      _ = fileHandle.availableData
    }

    let processChannel = ProcessChannel(process)
    let rpc = RPC(processChannel)
    api = .init(rpc)
  }

  public func bootstrap() async -> Int32 {
    try! process.run()

    let version = Bundle.main.version ?? (0, 0, 0)
    try! await api.nvimSetClientInfo(
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

    let initLua = try! String(
      data: Data(
        contentsOf: Bundle.main.resourceURL!
          .appending(path: "nvim")
          .appending(path: "init.lua"),
      ),
      encoding: .utf8,
    )!
    try! await api.nvimExecLua(code: initLua, args: [])

    try! await attachUI()

    return await withCheckedContinuation { continuation in
      process.terminationHandler = { process in
        continuation.resume(returning: process.terminationStatus)
      }
    }
  }

  public func reattach(to address: String) async throws {
    isReattaching.withLock { $0 = true }
    try api.rpc.reconnect(to: SocketChannel(path: address))
    try await sendClientInfo()
    try await attachUI()
    isReattaching.withLock { $0 = false }
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

  private func attachUI() async throws {
    let uiOptions: UIOptions = [
      .extMultigrid,
      .extHlstate,
      .extTabline,
    ]
    let outerGridSize = UserDefaults.standard.savedWindowGeometry?.outerGridSize
      ?? .init(columnsCount: 110, rowsCount: 34)
    try await api.nvimUIAttach(
      width: outerGridSize.columnsCount,
      height: outerGridSize.rowsCount,
      options: uiOptions.nvimUIAttachOptions,
    )
  }
}
