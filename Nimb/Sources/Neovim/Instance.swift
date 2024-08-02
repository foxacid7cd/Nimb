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
  public init(nvimResourcesURL: URL, initialOuterGridSize: IntegerSize) {
    self.nvimResourcesURL = nvimResourcesURL
    self.initialOuterGridSize = initialOuterGridSize

    var environment = ProcessInfo.processInfo.environment
    environment.merge(UserDefaults.standard.environmentOverlay, uniquingKeysWith: { _, newValue in newValue })
    environment["VIMRUNTIME"] = nvimResourcesURL.appending(path: "runtime").standardizedFileURL.path()
    process.environment = environment

    let shell = environment["SHELL"] ?? "/bin/zsh"
    process.executableURL = URL(filePath: shell)

    let vimrcArgument: String = switch UserDefaults.standard.vimrc {
    case .default:
      ""
    case .norc:
      " -u NORC"
    case .none:
      " -u NONE"
    case let .custom(url):
      " -u '\(url.path())'"
    }

    let nvimExecutablePath = Bundle.main.path(forAuxiliaryExecutable: "nvim")!
    process.arguments = ["-l", "-c", "'\(nvimExecutablePath)' --embed --headless" + vimrcArgument]

    process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser

    process.qualityOfService = .userInteractive

    let processChannel = ProcessChannel(process)
    let rpc = RPC(processChannel, maximumConcurrentRequests: 500)
    let api = API(rpc)
    self.api = api
    neovimNotificationsIterator = api.makeAsyncIterator()
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

  public func run() async throws {
    try process.run()

    let initLua = try String(data: Data(contentsOf: nvimResourcesURL.appending(path: "init.lua")), encoding: .utf8)!
    try await api.nvimExecLua(code: initLua, args: [])

    try await api.nvimSubscribe(event: "nvim_error_event")

    let uiOptions: UIOptions = [
      .extMultigrid,
      .extHlstate,
      .extCmdline,
      .extMessages,
      .extPopupmenu,
      .extTabline,
    ]
    try await api.nvimUIAttach(width: initialOuterGridSize.columnsCount, height: initialOuterGridSize.rowsCount, options: uiOptions.nvimUIAttachOptions)
  }

  public func report(keyPress: KeyPress) {
    let keys = keyPress.makeNvimKeyCode()
    try? api.fastCall(APIFunctions.NvimInput(keys: keys))
  }

  public func reportMouseMove(modifier: String, gridID: Grid.ID, point: IntegerPoint) {
    try? api.fastCall(APIFunctions.NvimInputMouse(
      button: "move",
      action: "",
      modifier: modifier,
      grid: gridID,
      row: point.row,
      col: point.column
    ))
  }

  public func reportScrollWheel(with direction: ScrollDirection, modifier: String, gridID: Grid.ID, point: IntegerPoint) {
    try? api.fastCall(APIFunctions.NvimInputMouse(button: "wheel", action: direction.rawValue, modifier: modifier, grid: gridID, row: point.row, col: point.column))
  }

  public func report(mouseButton: MouseButton, action: MouseAction, modifier: String, gridID: Grid.ID, point: IntegerPoint) {
    try? api.fastCall(APIFunctions.NvimInputMouse(
      button: mouseButton.rawValue,
      action: action.rawValue,
      modifier: modifier,
      grid: gridID,
      row: point.row,
      col: point.column
    ))
  }

  public func reportPopupmenuItemSelected(atIndex index: Int, isFinish: Bool) throws {
    try api.fastCall(APIFunctions.NvimSelectPopupmenuItem(item: index, insert: true, finish: isFinish, opts: [:]))
  }

  public func reportTablineBufferSelected(withID id: Buffer.ID) throws {
    try api.fastCall(APIFunctions.NvimSetCurrentBuf(bufferID: id))
  }

  public func reportTablineTabpageSelected(withID id: Tabpage.ID) throws {
    try api.fastCall(APIFunctions.NvimSetCurrentTabpage(tabpageID: id))
  }

  public func reportOuterGrid(changedSizeTo size: IntegerSize) {
    try? api.fastCall(APIFunctions.NvimUITryResizeGrid(
      grid: Grid.OuterID,
      width: size.columnsCount,
      height: size.rowsCount
    ))
  }

  public func reportPumBounds(rectangle: IntegerRectangle) throws {
    try api.fastCall(APIFunctions.NvimUIPumSetBounds(
      width: Double(rectangle.size.columnsCount),
      height: Double(rectangle.size.rowsCount),
      row: Double(rectangle.origin.row),
      col: Double(rectangle.origin.column)
    ))
  }

  public func reportPaste(text: String) throws {
    try api.fastCall(APIFunctions.NvimPaste(data: text, crlf: false, phase: -1))
  }

  public func bufTextForCopy() async throws -> String {
    let rawSuccess = try await api.nimb(method: "buf_text_for_copy")
    guard let text = rawSuccess.flatMap(\.string) else {
      throw Failure("success result is not a string", rawSuccess as Any)
    }
    return text
  }

  public func edit(url: URL) async throws {
    try await api.nimb(
      method: "edit",
      parameters: [.string(url.path(percentEncoded: false))]
    )
  }

  public func write() async throws {
    try await api.nimb(method: "write")
  }

  public func saveAs(url: URL) async throws {
    try await api.nimb(
      method: "save_as",
      parameters: [.string(url.path(percentEncoded: false))]
    )
  }

  public func close() async throws {
    try await api.nimb(method: "close")
  }

  public func quitAll() async throws {
    try await api.nimb(method: "quit_all")
  }

  public func requestCurrentBufferInfo() async throws -> (name: String, buftype: String) {
    async let name = api.nvimBufGetName(bufferID: .current)
    async let rawBuftype = api.nvimGetOptionValue(name: "buftype", opts: ["buf": .integer(0)])
    return try await (
      name: name,
      buftype: rawBuftype[case: \.string] ?? ""
    )
  }

  public func report(errorMessage: String) async throws {
    try await api.nimb(
      method: "echo_err",
      parameters: [.string(errorMessage)]
    )
  }

  public func stopinsert() {
    try? api.fastCall(APIFunctions.NvimCmd(
      cmd: [.string("cmd"): .string("stopinsert")],
      opts: [:]
    ))
  }

  private let nvimResourcesURL: URL
  private let initialOuterGridSize: IntegerSize
  private let process = Process()
  private let api: API<ProcessChannel>
  private nonisolated let neovimNotificationsIterator: API<ProcessChannel>.AsyncIterator
}

extension Instance: AsyncSequence {
  public typealias Element = [NeovimNotification]

  public nonisolated func makeAsyncIterator() -> API<ProcessChannel>.AsyncIterator {
    neovimNotificationsIterator
  }
}
