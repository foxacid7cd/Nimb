// SPDX-License-Identifier: MIT

import Foundation

public final class Neovim: Sendable {
  public let process: Process
  public let api: API<ProcessChannel>

  public init() {
    process = Process()

    var environment = ProcessInfo.processInfo.environment
    environment.merge(
      UserDefaults.standard.environmentOverlay,
      uniquingKeysWith: { _, newValue in newValue }
    )
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

    let shell = environment["SHELL"] ?? "/bin/zsh"
    process.executableURL = URL(filePath: shell)

    let nvimExecutablePath = Bundle.main.path(forAuxiliaryExecutable: "nvim")!
    if UserDefaults.standard.debug.isMessagePackInspectorEnabled {
      let inspectorExecutablePath: String = Bundle.main
        .path(forAuxiliaryExecutable: "msgpack-inspector")!

      let temporaryFileURL = FileManager.default.temporaryDirectory
        .appending(component: "captured_nvim_msgpack_output_\(UUID().uuidString).mpack")

      Task { @MainActor in
        logger.debug("Capturing nvim msgpack output to \(temporaryFileURL.path())")
      }

      process.arguments = [
        "-l",
        "-c",
        "'\(inspectorExecutablePath)' --output \(temporaryFileURL.path()) \(nvimExecutablePath) --embed" +
          vimrcArgument,
      ]
    } else {
      process.arguments = [
        "-l",
        "-c",
        "'\(nvimExecutablePath)' --embed" + vimrcArgument,
      ]
    }

    process.currentDirectoryURL = FileManager.default
      .homeDirectoryForCurrentUser

    process.qualityOfService = .userInitiated

    let processChannel = ProcessChannel(process)
    let rpc = RPC(processChannel, maximumConcurrentRequests: 1000)
    api = .init(rpc)
  }

  @MainActor
  public func bootstrap() async throws {
    try process.run()

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
      methods: ["nimb_notify": .dictionary(["async": true,
                                            "nargs": .integer(3)])],
      attributes: [:]
    )

    let initLua = try String(
      data: Data(
        contentsOf: Bundle.main.resourceURL!
          .appending(path: "nvim")
          .appending(path: "init.lua")
      ),
      encoding: .utf8
    )!
    try await api.nvimExecLua(code: initLua, args: [])

    try await api.nvimSubscribe(event: "nvim_error_event")

    let uiOptions: UIOptions = [
      .extMultigrid,
      .extHlstate,
      .extCmdline,
      .extTabline,
      .extMessages,
      .extWildmenu,
      .extPopupmenu,
    ]
    let initialOuterGridSize = UserDefaults.standard.outerGridSize
    try await api.nvimUIAttach(
      width: initialOuterGridSize.columnsCount,
      height: initialOuterGridSize.rowsCount,
      options: uiOptions.nvimUIAttachOptions
    )
  }
}
