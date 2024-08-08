// SPDX-License-Identifier: MIT

import Algorithms
import AsyncAlgorithms
import Collections
@preconcurrency import CustomDump
import Foundation

@MainActor
public class Store: Sendable {
  public init(instance: Instance, debug: State.Debug, font: Font) {
    self.instance = instance

    handleError = { @Sendable [alertMessages] (error: any Error) in
      _ = Task {
        await alertMessages.send(.init(error))
      }
    }

    let initialState = State(debug: debug, font: font)
    stateContainer = StateContainer(state: initialState)

    typealias StateAndUpdates = (state: State, updates: State.Updates)

    let applyUIEventsActions = AsyncThrowingStream(Action.self, bufferingPolicy: .unbounded) { [alertMessages, stateContainer] continuation in
      let task = Task.detached { @MainActor in
        do {
          for try await neovimNotificationsBatch in instance.api.neovimNotifications {
            try Task.checkCancellation()

            for notification in neovimNotificationsBatch {
              switch notification {
              case let .redraw(uiEvents):
                if stateContainer.state.debug.isUIEventsLoggingEnabled {
                  var string = ""
                  customDump(uiEvents, to: &string, maxDepth: 7)
                  logger.debug("UI events: \(string)")
                }

//                latestUIEventsBatch = uiEvents

                continuation.yield(Actions.ApplyUIEvents(uiEvents: uiEvents))

              case let .nvimErrorEvent(event):
                Task {
                  await alertMessages.send(.init(
                    content: "\(event.error) \(event.message)"
                  ))
                }

              case let .nimbNotify(value):
                customDump(continuation.yield(Actions.AddNimbNotifies(values: value)))
              }
            }
          }

          continuation.finish()
        } catch is CancellationError {
        } catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = {
        switch $0 {
        case .cancelled:
          task.cancel()
        default:
          break
        }
      }
    }

    stateUpdates = AsyncThrowingStream(State.Updates.self, bufferingPolicy: .unbounded) { [stateContainer, actionsChannel, handleError] continuation in
      let task = Task.detached { @MainActor in
        let sequence = merge(actionsChannel, applyUIEventsActions)
          .buffer(policy: .unbounded)
          .reductions(into: (state: initialState, updates: State.Updates())) { result, action in
            if result.updates.needFlush {
              result.updates = State.Updates(needFlush: false)
            }
            let updates = await action.apply(to: &result.state, handleError: handleError)
            result.updates.formUnion(updates)
          }
          .filter(\.updates.needFlush)
          ._throttle(for: .milliseconds(1000 / 60), clock: .continuous) { (accum: StateAndUpdates?, new: StateAndUpdates) in
            if let accum {
              var updates = accum.updates
              updates.formUnion(new.updates)
              var state = accum.state
              state.apply(updates: new.updates, from: new.state)
              return (state, updates)
            } else {
              return new
            }
          }

        do {
          for try await (state, updates) in sequence {
            try Task.checkCancellation()

            stateContainer.apply(updates: updates, from: state)
            continuation.yield(updates)
          }
        } catch is CancellationError {
        } catch {
          continuation.finish(throwing: error)
        }
      }

      continuation.onTermination = {
        switch $0 {
        case .cancelled:
          task.cancel()
        default:
          break
        }
      }
    }

//    startCursorBlinkingTask()
  }

  deinit {
    cursorBlinkingTask?.cancel()
  }

  public let stateUpdates: AsyncThrowingStream<State.Updates, any Error>

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
//    guard rectangle != previousPumBounds else {
//      return
//    }
//    previousPumBounds = rectangle
//
//    do {
//      try instance.reportPumBounds(rectangle: rectangle)
//    } catch {
//      handleError(error)
//    }
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

  fileprivate let handleError: @Sendable (any Error) -> Void

  private let instance: Instance
  private let stateContainer: StateContainer
  private let actionsChannel = AsyncChannel<Action>()
  private var cursorBlinkingTask: Task<Void, Never>?
  private var previousReportedOuterGridSize: IntegerSize?
  private var previousReportedOuterGridSizeInstant = ContinuousClock().now
  private var outerGridSizeThrottlingTask: Task<Void, Never>?
  private let outerGridSizeThrottlingInterval: Duration = .milliseconds(1000 / 120)
  private var previousMouseMove: (modifier: String, gridID: Grid.ID, point: IntegerPoint)?
  private var latestUIEventsBatch = [UIEvent]()

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
    store.handleError(error)
    return nil
  }
}

@MainActor
public func withAsyncErrorHandler<T>(from store: Store, _ body: @MainActor () async throws -> T) async -> T? {
  do {
    return try await body()
  } catch {
    store.handleError(error)
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
