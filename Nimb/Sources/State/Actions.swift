// SPDX-License-Identifier: MIT

import Foundation

public enum Actions {
  public struct ToggleDebugUIEventsLogging: Action {
    public func apply(to container: StateContainer) async throws -> State
      .Updates
    {
      container.state.debug.isUIEventsLoggingEnabled.toggle()
      return .init(isDebugUpdated: true)
    }
  }

  public struct ToggleDebugMessagePackInspector: Action {
    public func apply(to container: StateContainer) async throws -> State
      .Updates
    {
      container.state.debug.isMessagePackInspectorEnabled.toggle()
      return .init(isDebugUpdated: true)
    }
  }

  public struct ToggleStoreActionsLogging: Action {
    public func apply(to container: StateContainer) async throws -> State
      .Updates
    {
      container.state.debug.isStoreActionsLoggingEnabled.toggle()
      return .init(isDebugUpdated: true)
    }
  }

  @PublicInit
  public struct SetCursorBlinkingPhase: Action {
    public var value: Bool

    public func apply(to container: StateContainer) async throws -> State
      .Updates
    {
      container.state.cursorBlinkingPhase = value
      return .init(isCursorBlinkingPhaseUpdated: true)
    }
  }

  @PublicInit
  public struct SetFont: Action {
    public var value: Font

    public func apply(to container: StateContainer) async throws -> State
      .Updates
    {
      container.state.font = value
      container.state.flushDrawRuns()
      return .init(isFontUpdated: true)
    }
  }

  @PublicInit
  public struct AddNimbNotifies: Action {
    public var values: [NimbNotify]

    public func apply(to container: StateContainer) async throws -> State
      .Updates
    {
      container.state.nimbNotifies.append(contentsOf: values)
      return .init(isNimbNotifiesUpdated: true)
    }
  }
}
