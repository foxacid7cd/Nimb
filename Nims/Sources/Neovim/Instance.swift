// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import CasePaths
import Collections
import CustomDump
import Foundation
import Library
import MessagePack

@StateActor
public final class Instance: Sendable {
  public init(neovimRuntimeURL: URL, initialOuterGridSize: IntegerSize) {
    let nvimExecutablePath = Bundle.main.path(forAuxiliaryExecutable: "nvim")!
    let nvimArguments = ["--embed"]
    let nvimCommand = ([nvimExecutablePath] + nvimArguments)
      .joined(separator: " ")

    let process = Process()
    self.process = process
    process.executableURL = URL(filePath: "/bin/zsh")
    process.arguments = ["-l", "-c", nvimCommand]
    process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser

    let environmentOverlay: [String: String] = [
      "VIMRUNTIME": neovimRuntimeURL.standardizedFileURL.path(),
    ]

    var environment = ProcessInfo.processInfo.environment
    environment.merge(environmentOverlay, uniquingKeysWith: { $1 })
    process.environment = environment

    let processChannel = ProcessChannel(process)
    let rpc = RPC(processChannel)
    let api = API(rpc)
    self.api = api

    task = Task { [uiEventsChannel] in
      await withThrowingTaskGroup(of: Void.self) { taskGroup in
        taskGroup.addTask { @StateActor in
          var bufferedUIEvents = [UIEvent]()

          for try await uiEvents in api {
            try Task.checkCancellation()

            bufferedUIEvents += uiEvents

            if let last = uiEvents.last, case .flush = last {
              await uiEventsChannel.send(bufferedUIEvents)
              bufferedUIEvents.removeAll(keepingCapacity: true)
            }
          }
        }

        taskGroup.addTask { @StateActor in
          try process.run()

          let uiOptions: UIOptions = [
            .extMultigrid,
            .extHlstate,
            .extCmdline,
            .extMessages,
            .extPopupmenu,
            .extTabline,
          ]

          try await api.call(APIFunctions.NvimUIAttach(
            width: initialOuterGridSize.columnsCount,
            height: initialOuterGridSize.rowsCount,
            options: uiOptions.nvimUIAttachOptions
          ))
        }

        while !taskGroup.isEmpty {
          do {
            try await taskGroup.next()
          } catch is CancellationError {
          } catch {
            taskGroup.cancelAll()
            uiEventsChannel.fail(error)
          }
        }

        uiEventsChannel.finish()
      }
    }
  }

  deinit {
    task?.cancel()
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

  public func report(keyPress: KeyPress) async {
    let keys = keyPress.makeNvimKeyCode()
    try? await api.fastCall(APIFunctions.NvimInput(keys: keys))
  }

  public func reportMouseMove(modifier: String?, gridID: Grid.ID, point: IntegerPoint) async {
    if
      let previousMouseMove,
      previousMouseMove.modifier == modifier,
      previousMouseMove.gridID == gridID,
      previousMouseMove.point == point
    {
      return
    }
    previousMouseMove = (modifier, gridID, point)
    try? await api.fastCall(APIFunctions.NvimInputMouse(
      button: "move",
      action: "",
      modifier: modifier ?? "",
      grid: gridID,
      row: point.row,
      col: point.column
    ))
  }

  public func reportScrollWheel(with direction: ScrollDirection, modifier: String?, gridID: Grid.ID, point: IntegerPoint, count: Int) async {
    try? await api.fastCallsTransaction(with: Array(
      repeating: APIFunctions.NvimInputMouse(
        button: "wheel",
        action: direction.rawValue,
        modifier: modifier ?? "",
        grid: gridID,
        row: point.row,
        col: point.column
      ),
      count: count
    ))
  }

  public func report(mouseButton: MouseButton, action: MouseAction, modifier: String?, gridID: Grid.ID, point: IntegerPoint) async {
    try? await api.fastCall(APIFunctions.NvimInputMouse(
      button: mouseButton.rawValue,
      action: action.rawValue,
      modifier: modifier ?? "",
      grid: gridID,
      row: point.row,
      col: point.column
    ))
  }

  public func reportPopupmenuItemSelected(atIndex index: Int) async throws {
    try await api.fastCall(APIFunctions.NvimSelectPopupmenuItem(item: index, insert: true, finish: false, opts: [:]))
  }

  public func reportTablineBufferSelected(withID id: Buffer.ID) async throws {
    try await api.fastCall(APIFunctions.NvimSetCurrentBuf(bufferID: id))
  }

  public func reportTablineTabpageSelected(withID id: Tabpage.ID) async throws {
    try await api.fastCall(APIFunctions.NvimSetCurrentTabpage(tabpageID: id))
  }

  public func reportOuterGrid(changedSizeTo size: IntegerSize) async {
    guard size != previousReportedOuterGridSize else {
      return
    }
    previousReportedOuterGridSize = size

    guard outerGridSizeThrottlingTask == nil else {
      return
    }
    defer { previousReportedOuterGridSizeTime = .now }

    let timeElapsed = previousReportedOuterGridSizeTime.duration(to: .now)
    if timeElapsed > outerGridSizeThrottlingInterval {
      try? await api.fastCall(APIFunctions.NvimUITryResizeGrid(
        grid: Grid.OuterID,
        width: size.columnsCount,
        height: size.rowsCount
      ))
    } else {
      outerGridSizeThrottlingTask = Task { [weak self] in
        guard let self else {
          return
        }

        do {
          try await Task.sleep(for: outerGridSizeThrottlingInterval - timeElapsed)

          try? await api.fastCall(APIFunctions.NvimUITryResizeGrid(
            grid: Grid.OuterID,
            width: previousReportedOuterGridSize!.columnsCount,
            height: previousReportedOuterGridSize!.rowsCount
          ))

        } catch {}

        outerGridSizeThrottlingTask = nil
      }
    }
  }

  public func reportPumBounds(gridFrame: CGRect) async throws {
    if gridFrame != previousPumBounds {
      try await api.fastCall(APIFunctions.NvimUIPumSetBounds(
        width: gridFrame.width,
        height: gridFrame.height,
        row: gridFrame.origin.y,
        col: gridFrame.origin.x
      ))
      previousPumBounds = gridFrame
    }
  }

  public func reportPaste(text: String) async throws {
    try await api.fastCall(APIFunctions.NvimPaste(data: text, crlf: false, phase: -1))
  }

  public func bufTextForCopy() async throws -> String {
    let rawSuccess = try await api.nims(method: "buf_text_for_copy")
    guard let text = rawSuccess.flatMap(/Value.string) else {
      throw Failure("success result is not a string", rawSuccess as Any)
    }
    return text
  }

  public func edit(url: URL) async throws {
    try await api.nims(
      method: "edit",
      parameters: [.string(url.path(percentEncoded: false))]
    )
  }

  public func write() async throws {
    try await api.nims(method: "write")
  }

  public func saveAs(url: URL) async throws {
    try await api.nims(
      method: "save_as",
      parameters: [.string(url.path(percentEncoded: false))]
    )
  }

  public func quit() async throws {
    try await api.nims(method: "quit")
  }

  public func quitAll() async throws {
    try await api.nims(method: "quit_all")
  }

  public func requestCurrentBufferInfo() async throws -> (name: String, buftype: String) {
    async let name = api.nvimBufGetName(bufferID: .current)
    async let rawBuftype = api.nvimBufGetOption(bufferID: .current, name: "buftype")
    return try await (
      name: name,
      buftype: (/Value.string).extract(from: rawBuftype) ?? ""
    )
  }

  public func report(errorMessages: [String]) async throws {
    try await api.fastCallsTransaction(
      with: errorMessages
        .map(APIFunctions.NvimErrWriteln.init(str:))
    )
  }

  private let process: Process
  private let api: API<ProcessChannel>
  private let uiEventsChannel = AsyncThrowingChannel<[UIEvent], any Error>()
  private var previousMouseMove: (modifier: String?, gridID: Int, point: IntegerPoint)?
  private var previousPumBounds: CGRect?
  private var task: Task<Void, Never>?
  private let outerGridSizeThrottlingInterval = Duration.milliseconds(100)
  private var outerGridSizeThrottlingTask: Task<Void, Never>?
  private var previousReportedOuterGridSizeTime = SuspendingClock.now
  private var previousReportedOuterGridSize: IntegerSize?
}

extension Instance: AsyncSequence {
  public typealias Element = [UIEvent]

  public nonisolated func makeAsyncIterator() -> AsyncThrowingChannel<[UIEvent], any Error>.AsyncIterator {
    uiEventsChannel.makeAsyncIterator()
  }
}
