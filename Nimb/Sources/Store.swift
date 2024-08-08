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

    let initialState = State(debug: debug, font: font)
    stateContainer = StateContainer(state: initialState)

    let stateUpdatesChannel = AsyncChannel<State.Updates>()
    stateUpdates = stateUpdatesChannel

    actionsTask = Task { [stateContainer, handleError] in
      let sequence = actionsChannel
        .buffer(policy: .unbounded)
        .reductions(into: (state: initialState, updates: State.Updates())) { result, action in
          if result.updates.needFlush {
            result.updates = State.Updates()
          }
          let updates = await action.apply(to: &result.state, handleError: handleError)
          result.updates.formUnion(updates)
        }

      do {
        for await (state, updates) in sequence {
          try Task.checkCancellation()

          if updates.needFlush {
            stateContainer.apply(updates: updates, from: state)
            await stateUpdatesChannel.send(updates)
          }
        }
      } catch { }
    }

    instanceTask = Task {
      do {
        for try await neovimNotificationsBatch in instance {
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

              await actionsChannel.send(Actions.ApplyUIEvents(uiEvents: uiEvents))

            case let .nvimErrorEvent(event):
              Task {
                await alertMessages.send(.init(
                  content: "\(event.error) \(event.message)"
                ))
              }

            case let .nimbNotify(value):
              dispatch(Actions.AddNimbNotifies(values: value))
            }
          }
        }
      } catch is CancellationError {
      } catch {
        handleError(error)
      }
    }

    startCursorBlinkingTask()
  }

  deinit {
    actionsTask?.cancel()
    instanceTask?.cancel()
    cursorBlinkingTask?.cancel()
    outerGridSizeThrottlingTask?.cancel()
  }

  public let alertMessages = AsyncChannel<AlertMessage>()

  public var api: API<some Channel> {
    instance.api
  }

  public var state: State {
    stateContainer.state
  }

  public var font: Font {
    state.font
  }

  public var appearance: Appearance {
    state.appearance
  }

  public func set(font: Font) {
    dispatch(Actions.SetFont(value: font))
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
      handleError(error)
    }
  }

  public func reportTablineBufferSelected(withID id: Buffer.ID) {
    do {
      try instance.reportTablineBufferSelected(withID: id)
    } catch {
      handleError(error)
    }
  }

  public func reportTablineTabpageSelected(withID id: Tabpage.ID) {
    do {
      try instance.reportTablineTabpageSelected(withID: id)
    } catch {
      handleError(error)
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
      handleError(error)
    }
  }

  public func reportPaste(text: String) {
    do {
      try instance.reportPaste(text: text)
    } catch {
      handleError(error)
    }
  }

  public func requestTextForCopy() async -> String? {
    guard
      let mode = state.mode,
      let modeInfo = state.modeInfo
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
        let lastCmdlineLevel = state.cmdlines.lastCmdlineLevel,
        let cmdline = state.cmdlines.dictionary[lastCmdlineLevel]
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
      handleError(error)
    }
  }

  public func quitAll() async {
    do {
      try await instance.quitAll()
    } catch {
      handleError(error)
    }
  }

  public func requestCurrentBufferInfo() async
  -> (name: String, buftype: String)? {
    do {
      return try await instance.requestCurrentBufferInfo()
    } catch {
      handleError(error)
      return nil
    }
  }

  public func dumpState() -> String {
    var string = ""
    customDump(latestUIEventsBatch, to: &string)
    return string
  }

  public func dispatch(_ action: Action) {
    Task {
      await actionsChannel.send(action)
    }
  }

  let stateUpdates: AsyncChannel<State.Updates>

  private let instance: Instance
  private let stateContainer: StateContainer
  private let actionsChannel = AsyncChannel<Action>()
  private var actionsTask: Task<Void, Never>?
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

  private lazy var handleError = { @Sendable [alertMessages] (error: any Error) in
    _ = Task {
      await alertMessages.send(.init(error))
    }
  }

  private func startCursorBlinkingTask() {
    guard let cursorStyle = state.currentCursorStyle else {
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
      cursorBlinkingTask = Task {
        do {
          try await Task.sleep(for: .milliseconds(blinkWait))

          while true {
            dispatch(Actions.SetCursorBlinkingPhase(value: false))
            try await Task.sleep(for: .milliseconds(blinkOff))

            dispatch(Actions.SetCursorBlinkingPhase(value: true))
            try await Task.sleep(for: .milliseconds(blinkOn))
          }
        } catch { }
      }
    }
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
