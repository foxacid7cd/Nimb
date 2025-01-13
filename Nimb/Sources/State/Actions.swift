// SPDX-License-Identifier: MIT

import Foundation

public enum Actions {
  public struct ToggleDebugUIEventsLogging: Action {
    public func apply(to state: inout State, handleError: @Sendable (Error) -> Void) -> State.Updates {
      state.debug.isUIEventsLoggingEnabled.toggle()
      return .init(isDebugUpdated: true)
    }
  }

  public struct ToggleDebugMessagePackInspector: Action {
    public func apply(to state: inout State, handleError: @Sendable (Error) -> Void) -> State.Updates {
      state.debug.isMessagePackInspectorEnabled.toggle()
      return .init(isDebugUpdated: true)
    }
  }

  public struct ToggleStoreActionsLogging: Action {
    public func apply(to state: inout State, handleError: @Sendable (Error) -> Void) -> State.Updates {
      state.debug.isStoreActionsLoggingEnabled.toggle()
      return .init(isDebugUpdated: true)
    }
  }

  @PublicInit
  public struct SetCursorBlinkingPhase: Action {
    public var value: Bool

    public func apply(to state: inout State, handleError: @Sendable (Error) -> Void) -> State.Updates {
      state.cursorBlinkingPhase = value
      return .init(isCursorBlinkingPhaseUpdated: true)
    }
  }

  @PublicInit
  public struct SetFont: Action {
    public var value: Font

    public func apply(to state: inout State, handleError: @Sendable (Error) -> Void) -> State.Updates {
      state.font = value
      return .init(isFontUpdated: true)
    }
  }

  @PublicInit
  public struct AddNimbNotifies: Action {
    public var values: [NimbNotify]

    public func apply(to state: inout State, handleError: @Sendable (Error) -> Void) -> State.Updates {
      state.nimbNotifies.append(contentsOf: values)
      return .init(isNimbNotifiesUpdated: true)
    }
  }

  @PublicInit
  public struct SetApplicationActive: Action {
    public var value: Bool

    public func apply(to state: inout State, handleError: (any Error) -> Void) -> State.Updates {
      state.isApplicationActive = value
      return .init(isApplicationActiveUpdated: true)
    }
  }
}
