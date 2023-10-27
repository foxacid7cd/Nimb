// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import Foundation
import Library

@MainActor
public final class Store: Sendable {
  public init(instance: Instance, font: NimsFont) {
    self.instance = instance
    let state = State(instanceState: .init(font: font))
    self.state = state
    backgroundState = state

    task = Task { @NeovimActor [weak self] in
      do {
        for try await instanceStateUpdates in instance {
          guard let self else {
            return
          }

          try Task.checkCancellation()

          let state = instance.state
          self.backgroundState.instanceState = state

          var isMsgShowsDismissed: Bool?
          if instanceStateUpdates.isMsgShowsUpdated, !self.backgroundState.msgShows.isEmpty {
            self.hideMsgShowsTask?.cancel()
            self.hideMsgShowsTask = nil

            self.backgroundState.isMsgShowsDismissed = false
            isMsgShowsDismissed = false
          }

          Task { @MainActor [isMsgShowsDismissed] in
            self.state.instanceState = state
            if let isMsgShowsDismissed {
              self.state.isMsgShowsDismissed = isMsgShowsDismissed
            }
            await self.stateUpdatesChannel.send(
              .init(
                instanceStateUpdates: instanceStateUpdates,
                isMsgShowsDismissedUpdated: isMsgShowsDismissed != nil
              )
            )
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
    task?.cancel()
    hideMsgShowsTask?.cancel()
  }

  public let instance: Instance

  public var font: NimsFont {
    state.font
  }

  public var appearance: Appearance {
    state.appearance
  }

  public func scheduleHideMsgShowsIfPossible() {
    Task { @NeovimActor in
      if !backgroundState.hasModalMsgShows, !backgroundState.isMsgShowsDismissed, hideMsgShowsTask == nil {
        hideMsgShowsTask = Task { [weak self] in
          do {
            try await Task.sleep(for: .milliseconds(100))

            guard let self else {
              return
            }

            hideMsgShowsTask = nil
            backgroundState.isMsgShowsDismissed = true
            Task { @MainActor in
              self.state.isMsgShowsDismissed = true
              await self.stateUpdatesChannel.send(.init(isMsgShowsDismissedUpdated: true))
            }
          } catch {}
        }
      }
    }
  }

  private(set) var state: State

  private let stateUpdatesChannel = AsyncThrowingChannel<State.Updates, any Error>()
  @NeovimActor
  private var backgroundState: State
  private var task: Task<Void, Never>?
  @NeovimActor
  private var hideMsgShowsTask: Task<Void, Never>?
}

extension Store: AsyncSequence {
  public typealias Element = State.Updates

  public nonisolated func makeAsyncIterator() -> AsyncThrowingChannel<State.Updates, any Error>.AsyncIterator {
    stateUpdatesChannel.makeAsyncIterator()
  }
}
