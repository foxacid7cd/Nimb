// SPDX-License-Identifier: MIT

import Neovim

struct State: Sendable {
  var font = NimsFont()

  struct Updates: Sendable {
    var isFontUpdated = false
  }
}
