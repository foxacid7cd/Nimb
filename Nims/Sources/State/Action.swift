// SPDX-License-Identifier: MIT

import Foundation

public enum Action: Reducer {
  case toggleDebugUIEventsLogging
  case setCursorBlinkingPhase(Bool)
  case setFont(NimsFont)
  case setIsMsgShowsDismissed(Bool)

  public func reduce(state: State) async throws -> (state: State, updates: State.Updates) {
    var state = state
    var updates = State.Updates()

    switch self {
    case .toggleDebugUIEventsLogging:
      state.debug.isUIEventsLoggingEnabled.toggle()
      updates.isDebugUpdated = true

    case let .setCursorBlinkingPhase(value):
      state.cursorBlinkingPhase = value
      updates.isCursorBlinkingPhaseUpdated = true

    case let .setFont(value):
      state.font = value
      state.flushDrawRuns()
      updates.isFontUpdated = true

    case let .setIsMsgShowsDismissed(value):
      state.isMsgShowsDismissed = value
      updates.isMsgShowsDismissedUpdated = true
    }

    return (state, updates)
  }
}
