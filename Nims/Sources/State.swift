// SPDX-License-Identifier: MIT

import Library
import Neovim

@PublicInit
struct State: Sendable {
  var font: NimsFont = .init()

  @PublicInit
  struct Updates: Sendable {
    var isFontUpdated: Bool = false
  }
}
