// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import CustomDump
import Foundation
import Library

@MainActor
public class Store: Sendable {
  public init(instance: Instance, debug: State.Debug, font: NimsFont) {
    self.instance = instance

    let state = State(debug: debug, font: font)
    stateContainer = .init(state)
    self.state = state

    Task { @StateActor in
      startCursorBlinkingTask()
    }

    instanceTask = Task { @StateActor [weak self] in
      do {
        for try await uiEvents in instance {
          guard let self else {
            return
          }
          try Task.checkCancellation()

          if stateContainer.state.debug.isUIEventsLoggingEnabled {
            Loggers.uiEvents.debug("\(String(customDumping: uiEvents))")
          }

          try await dispatch(Actions.ApplyUIEvents(uiEvents: consume uiEvents))
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
    hideMsgShowsTask?.cancel()
    outerGridSizeThrottlingTask?.cancel()
  }

  public private(set) var state: State

  public var font: NimsFont {
    state.font
  }

  public var appearance: Appearance {
    state.appearance
  }

  @StateActor
  public func set(font: NimsFont) async {
    try? await dispatch(Actions.SetFont(value: font))
  }

  @StateActor
  public func scheduleHideMsgShowsIfPossible() {
    if !stateContainer.state.hasModalMsgShows, !stateContainer.state.isMsgShowsDismissed {
      hideMsgShowsTask?.cancel()

      hideMsgShowsTask = Task { [weak self] in
        do {
          try await Task.sleep(for: .milliseconds(50))

          guard let self else {
            return
          }

          hideMsgShowsTask = nil

          try? await dispatch(Actions.DismissMessages())
        } catch {}
      }
    }
  }

  @StateActor
  public func report(keyPress: KeyPress) async {
    await instance.report(keyPress: keyPress)
    scheduleHideMsgShowsIfPossible()
  }

  @StateActor
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

    await instance.reportMouseMove(modifier: modifier, gridID: gridID, point: point)
  }

  @StateActor
  public func reportScrollWheel(with direction: Instance.ScrollDirection, modifier: String?, gridID: Grid.ID, point: IntegerPoint, count: Int) async {
    await instance.reportScrollWheel(with: direction, modifier: modifier, gridID: gridID, point: point, count: count)
  }

  @StateActor
  public func report(mouseButton: Instance.MouseButton, action: Instance.MouseAction, modifier: String?, gridID: Grid.ID, point: IntegerPoint) async {
    if stateContainer.state.shouldNextMouseEventStopinsert {
      await instance.stopinsert()
    } else {
      await instance.report(mouseButton: mouseButton, action: action, modifier: modifier, gridID: gridID, point: point)
    }
  }

  @StateActor
  public func reportPopupmenuItemSelected(atIndex index: Int, isFinish: Bool) async {
    do {
      try await instance.reportPopupmenuItemSelected(atIndex: index, isFinish: isFinish)
    } catch {
      await handleActionError(error)
    }
  }

  @StateActor
  public func reportTablineBufferSelected(withID id: Buffer.ID) async {
    do {
      try await instance.reportTablineBufferSelected(withID: id)
    } catch {
      await handleActionError(error)
    }
  }

  @StateActor
  public func reportTablineTabpageSelected(withID id: Tabpage.ID) async {
    do {
      try await instance.reportTablineTabpageSelected(withID: id)
    } catch {
      await handleActionError(error)
    }
  }

  @StateActor
  public func reportOuterGrid(changedSizeTo size: IntegerSize) async {
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
      await instance.reportOuterGrid(changedSizeTo: size)
    } else {
      outerGridSizeThrottlingTask = Task { [weak self] in
        guard let self else {
          return
        }

        do {
          try await Task.sleep(for: outerGridSizeThrottlingInterval - sincePrevious)

          await instance.reportOuterGrid(changedSizeTo: previousReportedOuterGridSize!)
        } catch {}

        outerGridSizeThrottlingTask = nil
      }
    }
  }

  @StateActor
  public func reportPumBounds(rectangle: IntegerRectangle) async {
    guard rectangle != previousPumBounds else {
      return
    }
    previousPumBounds = rectangle

    do {
      try await instance.reportPumBounds(rectangle: rectangle)
    } catch {
      await handleActionError(error)
    }
  }

  @StateActor
  public func reportPaste(text: String) async {
    do {
      try await instance.reportPaste(text: text)
    } catch {
      await handleActionError(error)
    }
  }

  @StateActor
  public func requestTextForCopy() async -> String? {
    let backgroundState = stateContainer.state

    guard let mode = backgroundState.mode, let modeInfo = backgroundState.modeInfo else {
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

  @StateActor
  public func toggleUIEventsLogging() async {
    try? await dispatch(Actions.ToggleDebugUIEventsLogging())
  }

  @StateActor
  public func edit(url: URL) async {
    do {
      try await instance.edit(url: url)
    } catch {
      await handleActionError(error)
    }
  }

  @StateActor
  public func write() async {
    do {
      try await instance.write()
    } catch {
      await handleActionError(error)
    }
  }

  @StateActor
  public func saveAs(url: URL) async {
    do {
      try await instance.saveAs(url: url)
    } catch {
      await handleActionError(error)
    }
  }

  @StateActor
  public func close() async {
    do {
      try await instance.close()
    } catch {
      await handleActionError(error)
    }
  }

  @StateActor
  public func quitAll() async {
    do {
      try await instance.quitAll()
    } catch {
      await handleActionError(error)
    }
  }

  @StateActor
  public func requestCurrentBufferInfo() async -> (name: String, buftype: String)? {
    do {
      return try await instance.requestCurrentBufferInfo()
    } catch {
      await handleActionError(error)
      return nil
    }
  }

  private let instance: Instance
  @StateActor private var stateContainer: StateContainer
  private let stateThrottlingInterval = Duration.microseconds(1_000_000 / 120)
  @StateActor private var lastSetStateInstant = ContinuousClock.now
  @StateActor private var stateUpdatesAccumulator = State.Updates()
  @StateActor private var stateThrottlingTask: Task<Void, Never>?
  private let stateUpdatesChannel = AsyncThrowingChannel<State.Updates, any Error>()
  private var instanceTask: Task<Void, Never>?
  @StateActor private var cursorBlinkingTask: Task<Void, Never>?
  @StateActor private var hideMsgShowsTask: Task<Void, Never>?
  @StateActor private var previousPumBounds: IntegerRectangle?
  @StateActor private var previousMouseMove: (modifier: String?, gridID: Int, point: IntegerPoint)?
  @StateActor private let outerGridSizeThrottlingInterval = Duration.milliseconds(250)
  @StateActor private var outerGridSizeThrottlingTask: Task<Void, Never>?
  @StateActor private var previousReportedOuterGridSizeInstant = ContinuousClock.now
  @StateActor private var previousReportedOuterGridSize: IntegerSize?

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
        } catch {}
      }
    }
  }

  @StateActor
  private func dispatch(_ action: Action) async throws {
    var updates = try await action.apply(to: stateContainer)

    let shouldResetCursorBlinkingTask = updates.isCursorUpdated || updates.isMouseUserInteractionEnabledUpdated || updates.isCmdlinesUpdated
    if shouldResetCursorBlinkingTask {
      cursorBlinkingTask?.cancel()

      if !stateContainer.state.cursorBlinkingPhase {
        stateContainer.state.cursorBlinkingPhase = true
        updates.isCursorBlinkingPhaseUpdated = true
      }
    }

    if updates.isMessagesUpdated, !stateContainer.state.isMsgShowsDismissed {
      hideMsgShowsTask?.cancel()
      hideMsgShowsTask = nil
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
          } catch {}

          stateThrottlingTask = nil
        }
      }

      func synchronizeState() {
        Task { @MainActor [state = stateContainer.state, stateUpdatesAccumulator] in
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

  private func handleActionError(_ error: any Error) async {
    let errorMessage: String = if let error = error as? NimsNeovimError {
      error.errorMessages.joined(separator: "\n")
    } else if let error = error as? NeovimError {
      String(customDumping: error.raw)
    } else {
      String(customDumping: error)
    }
    if !errorMessage.isEmpty {
      do {
        try await instance.report(errorMessage: errorMessage)
      } catch {
        assertionFailure(Failure("reporting error message failed", error))
      }
    }
  }
}

extension Store: AsyncSequence {
  public typealias Element = State.Updates

  public nonisolated func makeAsyncIterator() -> AsyncThrowingChannel<State.Updates, any Error>.AsyncIterator {
    stateUpdatesChannel.makeAsyncIterator()
  }
}
