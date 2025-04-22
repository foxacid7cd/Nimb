// SPDX-License-Identifier: MIT

import Foundation

public final class Neovim: Sendable {
  public let process: Process
  public let api: API<ProcessChannel>

  public init() {
    process = Process()

    var environment = UserDefaults.standard.environmentOverlay
    environment["VIMRUNTIME"] = Bundle.main.resourceURL!
      .appending(path: "nvim")
      .appending(path: "runtime")
      .absoluteURL
      .path()
      .replacing(/\/$/, with: "")
    process.environment = environment

    let vimrcArgument: String =
      switch UserDefaults.standard.vimrc {
      case .default:
        ""
      case .norc:
        " -u NORC"
      case .none:
        " -u NONE"
      case let .custom(url):
        " -u '\(url.path())'"
      }

    let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    process.executableURL = URL(filePath: shell)

    let nvimExecutablePath = Bundle.main.path(forAuxiliaryExecutable: "nvim")!
    process.arguments = [
      "-l",
      "-c",
      "'\(nvimExecutablePath)' --embed" + vimrcArgument,
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
      ] as Value,
      type: "ui",
      methods: ["nimb_notify": .dictionary(["async": true,
                                            "nargs": .integer(3)])],
      attributes: [:]
    )

    let initLua = try! String(
      data: Data(
        contentsOf: Bundle.main.resourceURL!
          .appending(path: "nvim")
          .appending(path: "init.lua")
      ),
      encoding: .utf8
    )!
    try! await api.nvimExecLua(code: initLua, args: [])

//    try! await api.nvimSubscribe(event: "nvim_error_event")

    let uiOptions: UIOptions = [
      .extMultigrid,
      .extHlstate,
      .extCmdline,
      .extTabline,
      .extMessages,
//      .extWildmenu,
//      .extPopupmenu,
    ]
    let initialOuterGridSize = UserDefaults.standard.outerGridSize
    try! await api.nvimUIAttach(
      width: initialOuterGridSize.columnsCount,
      height: initialOuterGridSize.rowsCount,
      options: .dictionary(uiOptions.nvimUIAttachOptions)
    )

    return await withUnsafeContinuation { continuation in
      process.terminationHandler = { process in
        continuation.resume(returning: process.terminationStatus)
      }
    }
  }
}
