// SPDX-License-Identifier: MIT

import Library
import Neovim
import Overture

@PublicInit
@dynamicMemberLookup
struct State: Sendable {
  @PublicInit
  @dynamicMemberLookup
  struct Updates: Sendable {
    var instanceStateUpdates: Neovim.State.Updates = .init()
    var isFontUpdated: Bool = false
    var isCursorBlinkingPhaseUpdated: Bool = false
    var isMsgShowsDismissedUpdated: Bool = false

    subscript<Value>(dynamicMember keyPath: KeyPath<Neovim.State.Updates, Value>) -> Value {
      instanceStateUpdates[keyPath: keyPath]
    }
  }

  var instanceState: Neovim.State = .init()
  var font: NimsFont = .init()
  var cursorBlinkingPhase: Bool = false
  var isMsgShowsDismissed: Bool = false

  subscript<Value>(dynamicMember keyPath: KeyPath<Neovim.State, Value>) -> Value {
    instanceState[keyPath: keyPath]
  }
}
