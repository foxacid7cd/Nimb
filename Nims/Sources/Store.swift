// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import Foundation
import Library

@MainActor
public final class Store: Sendable {
  public init(instance: Instance, font: NimsFont) {
    self.instance = instance

    let state = State(font: font)
    backgroundState = state
    self.state = state

    reducerChannelTask = Task { @StateActor [weak self, reducerChannel] in
      do {
        for try await reducer in reducerChannel {
          guard let self else {
            return
          }
          try Task.checkCancellation()

          var (state, updates) = try await reducer.reduce(state: self.backgroundState)

          if updates.isCursorUpdated {
            self.resetCursorBlinkingTask()
          }

          if updates.isMsgShowsUpdated, !state.msgShows.isEmpty {
            self.hideMsgShowsTask?.cancel()
            self.hideMsgShowsTask = nil

            state.isMsgShowsDismissed = false
            updates.isMsgShowsDismissedUpdated = true
          }

          self.backgroundState = state
          Task { @MainActor [state, updates] in
            self.state = state
            await self.stateUpdatesChannel.send(updates)
          }
        }

        self?.stateUpdatesChannel.finish()
      } catch is CancellationError {
      } catch {
        self?.stateUpdatesChannel.fail(error)
      }
    }

    instanceTask = Task { @StateActor [weak self, reducerChannel] in
      do {
        for try await uiEvents in instance {
          guard let self else {
            return
          }
          try Task.checkCancellation()

          if backgroundState.debug.isUIEventsLoggingEnabled {
            Loggers.uiEvents.info("\(String(customDumping: uiEvents))")
          }

          await reducerChannel.send(
            ApplyUIEvents(uiEvents: uiEvents)
          )
        }

        reducerChannel.finish()
      } catch is CancellationError {
      } catch {
        reducerChannel.fail(error)
      }
    }
  }

  deinit {
    reducerChannelTask?.cancel()
    instanceTask?.cancel()
  }

  public private(set) var state: State

  public var font: NimsFont {
    state.font
  }

  public var appearance: Appearance {
    state.appearance
  }

  public nonisolated func set(font: NimsFont) {
    Task { @StateActor in
      await reducerChannel.send(Action.setFont(font))
    }
  }

  public nonisolated func scheduleHideMsgShowsIfPossible() {
    Task { @StateActor in
      if !backgroundState.hasModalMsgShows, !backgroundState.isMsgShowsDismissed, hideMsgShowsTask == nil {
        hideMsgShowsTask = Task { [weak self] in
          do {
            try await Task.sleep(for: .milliseconds(100))

            guard let self else {
              return
            }

            hideMsgShowsTask = nil
            await reducerChannel.send(Action.setIsMsgShowsDismissed(true))
          } catch {}
        }
      }
    }
  }

  public nonisolated func report(keyPress: KeyPress) {
    Task { @StateActor in
      await instance.report(keyPress: keyPress)
    }
  }

  public nonisolated func reportMouseMove(modifier: String?, gridID: Grid.ID, point: IntegerPoint) {
    instance.reportMouseMove(modifier: modifier, gridID: gridID, point: point)
  }

  public nonisolated func reportScrollWheel(with direction: Instance.ScrollDirection, modifier: String?, gridID: Grid.ID, point: IntegerPoint, count: Int) {
    instance.reportScrollWheel(with: direction, modifier: modifier, gridID: gridID, point: point, count: count)
  }

  public nonisolated func report(mouseButton: Instance.MouseButton, action: Instance.MouseAction, modifier: String?, gridID: Grid.ID, point: IntegerPoint) {
    instance.report(mouseButton: mouseButton, action: action, modifier: modifier, gridID: gridID, point: point)
  }

  public nonisolated func reportPopupmenuItemSelected(atIndex index: Int) {
    Task { @StateActor in
      await instance.reportPopupmenuItemSelected(atIndex: index)
    }
  }

  public nonisolated func reportTablineBufferSelected(withID id: Buffer.ID) {
    Task { @StateActor in
      await instance.reportTablineBufferSelected(withID: id)
    }
  }

  public nonisolated func reportTablineTabpageSelected(withID id: Tabpage.ID) {
    Task { @StateActor in
      await instance.reportTablineTabpageSelected(withID: id)
    }
  }

  public nonisolated func report(gridWithID id: Grid.ID, changedSizeTo size: IntegerSize) {
    Task { @StateActor in
      await instance.report(gridWithID: id, changedSizeTo: size)
    }
  }

  public nonisolated func reportPumBounds(gridFrame: CGRect) {
    Task { @StateActor in
      await instance.reportPumBounds(gridFrame: gridFrame)
    }
  }

  public nonisolated func reportPaste(text: String) {
    Task { @StateActor in
      await instance.reportPaste(text: text)
    }
  }

  public func reportCopy() async -> String? {
    guard let mode = state.mode, let modeInfo = state.modeInfo else {
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
      return await instance.bufTextForCopy()

    case "c":
      if let lastCmdlineLevel = state.cmdlines.lastCmdlineLevel, let cmdline = state.cmdlines.dictionary[lastCmdlineLevel] {
        return cmdline.contentParts
          .map(\.text)
          .joined()
      }

    default:
      break
    }

    return nil
  }

  public nonisolated func toggleUIEventsLogging() {
    Task { @StateActor in
      await reducerChannel.send(Action.toggleDebugUIEventsLogging)
    }
  }

  private let instance: Instance
  @StateActor private var backgroundState: State
  private let reducerChannel = AsyncThrowingChannel<Reducer, any Error>()
  private let stateUpdatesChannel = AsyncThrowingChannel<State.Updates, any Error>()
  private var reducerChannelTask: Task<Void, Never>?
  private var instanceTask: Task<Void, Never>?
  @StateActor private var cursorBlinkingTask: Task<Void, Never>?
  @StateActor private var hideMsgShowsTask: Task<Void, Never>?

  private nonisolated func resetCursorBlinkingTask() {
    Task { @StateActor [reducerChannel] in
      cursorBlinkingTask?.cancel()

      if !backgroundState.cursorBlinkingPhase {
        await reducerChannel.send(Action.setCursorBlinkingPhase(true))
      }

      if
        backgroundState.cmdlines.dictionary.isEmpty,
        let cursorStyle = backgroundState.currentCursorStyle,
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

              backgroundState.cursorBlinkingPhase = false
              await self.stateUpdatesChannel.send(.init(isCursorBlinkingPhaseUpdated: true))

              try await Task.sleep(for: .milliseconds(blinkOff))

              backgroundState.cursorBlinkingPhase = true
              await self.stateUpdatesChannel.send(.init(isCursorBlinkingPhaseUpdated: true))

              try await Task.sleep(for: .milliseconds(blinkOn))
            }
          } catch {}
        }
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
