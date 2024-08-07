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

    bufferingStateContainer = .init(.init(
      debug: debug,
      font: font
    ))

    startCursorBlinkingTask()

    instanceTask = Task { [weak self] in
      do {
        for try await neovimNotificationsBatch in instance {
          guard let self else {
            return
          }
          try Task.checkCancellation()

          for notification in neovimNotificationsBatch {
            switch notification {
            case let .redraw(uiEvents):
              if state.debug.isUIEventsLoggingEnabled {
                var string = ""
                customDump(uiEvents, to: &string, maxDepth: 7)
                logger.debug("UI events: \(string)")
              }

              latestUIEventsBatch = uiEvents

              try await dispatch(Actions.ApplyUIEvents(uiEvents: uiEvents))

            case let .nvimErrorEvent(event):
              await alertMessages.send(.init(
                content: "\(event.error) \(event.message)"
              ))

            case let .nimbNotify(value):
              try await dispatch(Actions.AddNimbNotifies(values: value))
            }
          }
        }
      } catch is CancellationError {
      } catch {
        await self?.alertMessages.send(.init(error))
      }
    }
  }

  deinit {
    instanceTask?.cancel()
    cursorBlinkingTask?.cancel()
    outerGridSizeThrottlingTask?.cancel()
  }

  public let alertMessages = AsyncChannel<AlertMessage>()

  public var api: API<some Channel> {
    instance.api
  }

  public var state: State {
    bufferingStateContainer.state
  }

  public var font: Font {
    state.font
  }

  public var appearance: Appearance {
    state.appearance
  }

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
      Task {
        await alertMessages.send(.init(error))
      }
    }
  }

  public func reportTablineBufferSelected(withID id: Buffer.ID) {
    do {
      try instance.reportTablineBufferSelected(withID: id)
    } catch {
      Task {
        await alertMessages.send(.init(error))
      }
    }
  }

  public func reportTablineTabpageSelected(withID id: Tabpage.ID) {
    do {
      try instance.reportTablineTabpageSelected(withID: id)
    } catch {
      Task {
        await alertMessages.send(.init(error))
      }
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
      Task {
        await alertMessages.send(.init(error))
      }
    }
  }

  public func reportPaste(text: String) {
    do {
      try instance.reportPaste(text: text)
    } catch {
      Task {
        await alertMessages.send(.init(error))
      }
    }
  }

  public func requestTextForCopy() async -> String? {
    let backgroundState = bufferingStateContainer.state

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
        Task {
          await alertMessages.send(.init(error))
        }
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

  public func close() async {
    do {
      try await instance.close()
    } catch {
      Task {
        await alertMessages.send(.init(error))
      }
    }
  }

  public func quitAll() async {
    do {
      try await instance.quitAll()
    } catch {
      Task {
        await alertMessages.send(.init(error))
      }
    }
  }

  public func requestCurrentBufferInfo() async
    -> (name: String, buftype: String)?
  {
    do {
      return try await instance.requestCurrentBufferInfo()
    } catch {
      Task {
        await alertMessages.send(.init(error))
      }
      return nil
    }
  }

  public func dumpState() -> String {
    var string = ""
    customDump(latestUIEventsBatch, to: &string)
    return string
  }

  public func dispatch(_ action: Action) async throws {
    if state.debug.isStoreActionsLoggingEnabled {
      var string = ""
      customDump(action, to: &string, maxDepth: 2)
      logger.debug("Store action dispatched \(string)")
    }

    let updates = try await action.apply(
      to: bufferingStateContainer.bufferedView
    )

    bufferedStateUpdates.formUnion(updates)
    let isFlushNeeded = bufferedStateUpdates.needFlush

    if isFlushNeeded {
      bufferingStateContainer.state.apply(
        updates: bufferedStateUpdates,
        from: bufferingStateContainer.bufferedState
      )
      await stateUpdatesChannel.send(bufferedStateUpdates)
      bufferedStateUpdates = .init()
    }

    //		} shouldResetCursorBlinkingTask = updates.isCursorUpdated || updates
//      .isMouseUserInteractionEnabledUpdated || updates.isCmdlinesUpdated
//    if shouldResetCursorBlinkingTask {
//      cursorBlinkingTask?.cancel()
//
//      if !bufferingStateContainer.state.cursorBlinkingPhase {
//        bufferingStateContainer.state.cursorBlinkingPhase = true
//        updates.isCursorBlinkingPhaseUpdated = true
//      }
//    }

//    if shouldResetCursorBlinkingTask {
//      startCursorBlinkingTask()
//    }
  }

  private let instance: Instance
  private var bufferingStateContainer: BufferingStateContainer
  private var bufferedStateUpdates = State.Updates()
  private let stateUpdatesChannel = AsyncThrowingChannel<
    State.Updates,
    any Error
  >()
  private var instanceTask: Task<Void, Never>?
  private var cursorBlinkingTask: Task<Void, Never>?
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
  private var latestUIEventsBatch: [UIEvent]?

  private func startCursorBlinkingTask() {
    guard let cursorStyle = bufferingStateContainer.state.currentCursorStyle else {
      return
    }
    if
      let blinkWait = cursorStyle.blinkWait,
      blinkWait > 0,
      let blinkOff = cursorStyle.blinkOff,
      blinkOff > 0,
      let blinkOn = cursorStyle.blinkOn,
      blinkOn > 0
    {
      cursorBlinkingTask = Task { @MainActor [weak self] in
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
}

extension Store: AsyncSequence {
  public typealias Element = State.Updates

  public func makeAsyncIterator() -> AsyncThrowingChannel<State.Updates, any Error>.AsyncIterator {
    stateUpdatesChannel.makeAsyncIterator()
  }
}

@MainActor
public func withErrorHandler<T>(from store: Store, _ body: @MainActor () throws -> T) -> T? {
  do {
    return try body()
  } catch {
    Task {
      await store.alertMessages.send(.init(error))
    }
    return nil
  }
}

@MainActor
public func withAsyncErrorHandler<T>(from store: Store, _ body: @MainActor () async throws -> T) async -> T? {
  do {
    return try await body()
  } catch {
    Task {
      await store.alertMessages.send(.init(error))
    }
    return nil
  }
}

@PublicInit
public struct AlertMessage: Sendable {
  public init(_ error: Error) {
    content =
      if let error = error as? NimbNeovimError {
        error.errorMessages.joined(separator: "\n")
      } else if let error = error as? NeovimError {
        String(customDumping: error.raw)
      } else {
        String(customDumping: error)
      }
  }

  public var content: String
}
