// SPDX-License-Identifier: MIT

import Library
import Neovim

@PublicInit
struct State: Sendable {
  @PublicInit
  struct Updates: Sendable {
    var isFontUpdated: Bool = false
  }

  var font: NimsFont = .init()
}
