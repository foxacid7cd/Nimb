// SPDX-License-Identifier: MIT

import Foundation
import Library

public enum Actions {
  public struct ToggleDebugUIEventsLogging: Action {
    public func apply(to container: StateContainer) async throws -> State.Updates {
      container.state.debug.isUIEventsLoggingEnabled.toggle()
      return .init(isDebugUpdated: true)
    }
  }

  @PublicInit
  public struct SetCursorBlinkingPhase: Action {
    public var value: Bool

    public func apply(to container: StateContainer) async throws -> State.Updates {
      container.state.cursorBlinkingPhase = value
      return .init(isCursorBlinkingPhaseUpdated: true)
    }
  }

  @PublicInit
  public struct SetFont: Action {
    public var value: Font

    public func apply(to container: StateContainer) async throws -> State.Updates {
      container.state.font = value
      return .init(font: value)
    }
  }

  public struct DismissMessages: Action {
    public func apply(to container: StateContainer) async throws -> State.Updates {
      container.state.isMsgShowsDismissed = true
      return .init(isMessagesUpdated: true)
    }
  }
}
