// SPDX-License-Identifier: MIT

import Algorithms
import AsyncAlgorithms
import Collections
import CustomDump
import Foundation

@MainActor
public class Store: Sendable {
  public init(instance: Instance, debug: State.Debug, font: Font) {
    self.instance = instance

    let state = State(debug: debug, font: font)
    stateContainer = .init(state)
    self.state = state

    Task { @StateActor in
      startCursorBlinkingTask()
    }

    instanceTask = Task { @StateActor [weak self] in
      var bufferedUIEventsBatches = [[UIEvent]]()

      do {
        for try await neovimNotificationsBatch in instance {
          guard let self else {
            return
          }
          try Task.checkCancellation()

          for notification in neovimNotificationsBatch {
            switch notification {
            case let .redraw(uiEvents):
              if stateContainer.state.debug.isUIEventsLoggingEnabled {
                var string = ""
                customDump(uiEvents, to: &string, maxDepth: 7)
                logger.debug("UI events: \(string)")
              }

              latestUIEventsBatch = uiEvents

              bufferedUIEventsBatches.append(uiEvents)

              if case .flush = uiEvents.last {
                try await dispatch(
                  Actions.ApplyUIEvents(
                    uiEvents: bufferedUIEventsBatches
                      .lazy
                      .flatMap { $0 }
                  )
                )
                bufferedUIEventsBatches.removeAll(keepingCapacity: true)

                await Task.yield()
              }

            case let .nvimErrorEvent(event):
              throw Failure("Received nvimErrorEvent \(event)")
            }
          }
        }

        self?.stateUpdatesChannel.finish()
      } catch is CancellationError {
      } catch {
        self?.stateUpdatesChannel.fail(error)
      }
    }
  }

  deinit {
    stateThrottlingTask?.cancel()
    instanceTask?.cancel()
    cursorBlinkingTask?.cancel()
    outerGridSizeThrottlingTask?.cancel()
  }

  public private(set) var state: State

  public var font: Font {
    state.font
  }

  public var appearance: Appearance {
    state.appearance
  }

  @StateActor
  public func set(font: Font) async {
    try? await dispatch(Actions.SetFont(value: font))
  }

  public func report(keyPress: KeyPress) {
    instance.report(keyPress: keyPress)
  }

  public func reportMouseMove(
    modifier: String,
    gridID: Grid.ID,
    point: IntegerPoint
  ) {
    if
      let previousMouseMove,
      previousMouseMove.modifier == modifier,
      previousMouseMove.gridID == gridID,
      previousMouseMove.point == point
    {
      return
    }
    previousMouseMove = (modifier, gridID, point)

    instance.reportMouseMove(modifier: modifier, gridID: gridID, point: point)
  }

  public func reportScrollWheel(
    with direction: Instance.ScrollDirection,
    modifier: String,
    gridID: Grid.ID,
    point: IntegerPoint
  ) {
    instance.reportScrollWheel(
      with: direction,
      modifier: modifier,
      gridID: gridID,
      point: point
    )
  }

  public func report(
    mouseButton: Instance.MouseButton,
    action: Instance.MouseAction,
    modifier: String,
    gridID: Grid.ID,
    point: IntegerPoint
  ) {
    instance.report(
      mouseButton: mouseButton,
      action: action,
      modifier: modifier,
      gridID: gridID,
      point: point
    )
  }

  public func reportPopupmenuItemSelected(atIndex index: Int, isFinish: Bool) {
    do {
      try instance.reportPopupmenuItemSelected(
        atIndex: index,
        isFinish: isFinish
      )
    } catch {
      handleActionError(error)
    }
  }

  public func reportTablineBufferSelected(withID id: Buffer.ID) {
    do {
      try instance.reportTablineBufferSelected(withID: id)
    } catch {
      handleActionError(error)
    }
  }

  public func reportTablineTabpageSelected(withID id: Tabpage.ID) {
    do {
      try instance.reportTablineTabpageSelected(withID: id)
    } catch {
      handleActionError(error)
    }
  }

  public func reportOuterGrid(changedSizeTo size: IntegerSize) {
    guard size != previousReportedOuterGridSize else {
      return
    }
    previousReportedOuterGridSize = size

    guard outerGridSizeThrottlingTask == nil else {
      return
    }
    defer { previousReportedOuterGridSizeInstant = .now }

    let sincePrevious = previousReportedOuterGridSizeInstant.duration(to: .now)
    if sincePrevious > outerGridSizeThrottlingInterval {
      instance.reportOuterGrid(changedSizeTo: size)
    } else {
      outerGridSizeThrottlingTask = Task { [weak self] in
        guard let self else {
          return
        }

        do {
          try await Task
            .sleep(for: outerGridSizeThrottlingInterval - sincePrevious)

          instance
            .reportOuterGrid(changedSizeTo: previousReportedOuterGridSize!)
        } catch { }

        outerGridSizeThrottlingTask = nil
      }
    }
  }

  public func reportPumBounds(rectangle: IntegerRectangle) {
    guard rectangle != previousPumBounds else {
      return
    }
    previousPumBounds = rectangle

    do {
      try instance.reportPumBounds(rectangle: rectangle)
    } catch {
      handleActionError(error)
    }
  }

  public func reportPaste(text: String) {
    do {
      try instance.reportPaste(text: text)
    } catch {
      handleActionError(error)
    }
  }

  @StateActor
  public func requestTextForCopy() async -> String? {
    let backgroundState = stateContainer.state

    guard
      let mode = backgroundState.mode,
      let modeInfo = backgroundState.modeInfo
    else {
      return nil
    }

    let shortName = modeInfo.cursorStyles[mode.cursorStyleIndex].shortName

    switch shortName?.lowercased().first {
    case "i",
         "n",
         "o",
         "r",
         "s",
         "v":
      do {
        return try await instance.bufTextForCopy()
      } catch {
        await handleActionError(error)
        return nil
      }

    case "c":
      if
        let lastCmdlineLevel = backgroundState.cmdlines.lastCmdlineLevel,
        let cmdline = backgroundState.cmdlines.dictionary[lastCmdlineLevel]
      {
        return cmdline.contentParts
          .map(\.text)
          .joined()
      }

    default:
      break
    }

    return nil
  }

  public func toggleUIEventsLogging() async {
    try? await dispatch(Actions.ToggleDebugUIEventsLogging())
  }

  public func toggleMessagePackInspector() async {
    try? await dispatch(Actions.ToggleDebugMessagePackInspector())
  }

  public func edit(url: URL) async {
    do {
      try await instance.edit(url: url)
    } catch {
      handleActionError(error)
    }
  }

  public func write() async {
    do {
      try await instance.write()
    } catch {
      handleActionError(error)
    }
  }

  public func saveAs(url: URL) async {
    do {
      try await instance.saveAs(url: url)
    } catch {
      handleActionError(error)
    }
  }

  public func close() async {
    do {
      try await instance.close()
    } catch {
      handleActionError(error)
    }
  }

  public func quitAll() async {
    do {
      try await instance.quitAll()
    } catch {
      handleActionError(error)
    }
  }

  public func requestCurrentBufferInfo() async
    -> (name: String, buftype: String)?
  {
    do {
      return try await instance.requestCurrentBufferInfo()
    } catch {
      handleActionError(error)
      return nil
    }
  }

  @StateActor
  public func dumpState() -> String {
    var string = ""
    customDump(latestUIEventsBatch, to: &string)
    return string
  }

  private let instance: Instance
  @StateActor private var stateContainer: StateContainer
  private let stateThrottlingInterval = Duration.microseconds(1_000_000 / 90)
  @StateActor private var lastSetStateInstant = ContinuousClock.now
  @StateActor private var stateUpdatesAccumulator = State.Updates()
  @StateActor private var stateThrottlingTask: Task<Void, Never>?
  private let stateUpdatesChannel = AsyncThrowingChannel<
    State.Updates,
    any Error
  >()
  private var instanceTask: Task<Void, Never>?
  @StateActor private var cursorBlinkingTask: Task<Void, Never>?
  private var previousPumBounds: IntegerRectangle?
  private var previousMouseMove: (
    modifier: String,
    gridID: Int,
    point: IntegerPoint
  )?
  private let outerGridSizeThrottlingInterval = Duration.milliseconds(100)
  private var outerGridSizeThrottlingTask: Task<Void, Never>?
  private var previousReportedOuterGridSizeInstant = ContinuousClock.now
  private var previousReportedOuterGridSize: IntegerSize?
  @StateActor private var latestUIEventsBatch: [UIEvent]?

  @StateActor
  private func startCursorBlinkingTask() {
    if
      let cursorStyle = stateContainer.state.currentCursorStyle,
      let blinkWait = cursorStyle.blinkWait,
      blinkWait > 0,
      let blinkOff = cursorStyle.blinkOff,
      blinkOff > 0,
      let blinkOn = cursorStyle.blinkOn,
      blinkOn > 0
    {
      cursorBlinkingTask = Task { @StateActor [weak self] in
        do {
          try await Task.sleep(for: .milliseconds(blinkWait))

          while true {
            guard let self else {
              return
            }

            try await dispatch(Actions.SetCursorBlinkingPhase(value: false))
            try await Task.sleep(for: .milliseconds(blinkOff))

            try await dispatch(Actions.SetCursorBlinkingPhase(value: true))
            try await Task.sleep(for: .milliseconds(blinkOn))
          }
        } catch { }
      }
    }
  }

  @StateActor
  private func dispatch(_ action: Action) async throws {
    var updates = try await action.apply(to: stateContainer)

    let shouldResetCursorBlinkingTask = updates.isCursorUpdated || updates
      .isMouseUserInteractionEnabledUpdated || updates.isCmdlinesUpdated
    if shouldResetCursorBlinkingTask {
      cursorBlinkingTask?.cancel()

      if !stateContainer.state.cursorBlinkingPhase {
        stateContainer.state.cursorBlinkingPhase = true
        updates.isCursorBlinkingPhaseUpdated = true
      }
    }

    stateUpdatesAccumulator.formUnion(updates)

    if stateThrottlingTask == nil {
      let sincePrevious = lastSetStateInstant.duration(to: .now)
      defer { lastSetStateInstant = .now }

      if sincePrevious > stateThrottlingInterval {
        synchronizeState()
      } else {
        stateThrottlingTask = Task { [weak self] in
          guard let self else {
            return
          }

          do {
            try await Task.sleep(for: stateThrottlingInterval - sincePrevious)
            synchronizeState()
          } catch { }

          stateThrottlingTask = nil
        }
      }

      func synchronizeState() {
        Task { @MainActor [
          state = stateContainer.state,
          stateUpdatesAccumulator
        ] in
          self.state = state
          await self.stateUpdatesChannel.send(stateUpdatesAccumulator)
        }
        stateUpdatesAccumulator = .init()
      }
    }

    if shouldResetCursorBlinkingTask {
      startCursorBlinkingTask()
    }
  }

  private func handleActionError(_ error: any Error) {
    let errorMessage: String =
      if let error = error as? NimbNeovimError {
        error.errorMessages.joined(separator: "\n")
      } else if let error = error as? NeovimError {
        String(customDumping: error.raw)
      } else {
        String(customDumping: error)
      }
    if !errorMessage.isEmpty {
      Task {
        do {
          try await instance.report(errorMessage: errorMessage)
        } catch {
          logger.error("reporting error message failed with error \(error)")
        }
      }
    }
  }
}

extension Store: AsyncSequence {
  public typealias Element = State.Updates

  public nonisolated func makeAsyncIterator()
    -> AsyncThrowingChannel<State.Updates, any Error>
    .AsyncIterator
  {
    stateUpdatesChannel.makeAsyncIterator()
  }
}
