// SPDX-License-Identifier: MIT

import Library
import Overture

@PublicInit
@dynamicMemberLookup
public struct State: Sendable {
  @PublicInit
  @dynamicMemberLookup
  public struct Updates: Sendable {
    public var instanceStateUpdates: NeovimState.Updates = .init()
    public var isMsgShowsDismissedUpdated: Bool = false

    public subscript<Value>(dynamicMember keyPath: KeyPath<NeovimState.Updates, Value>) -> Value {
      instanceStateUpdates[keyPath: keyPath]
    }
  }

  public var instanceState: NeovimState = .init()
  public var isMsgShowsDismissed: Bool = false

  public subscript<Value>(dynamicMember keyPath: KeyPath<NeovimState, Value>) -> Value {
    instanceState[keyPath: keyPath]
  }
}
