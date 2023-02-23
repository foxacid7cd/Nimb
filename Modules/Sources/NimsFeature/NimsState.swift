// SPDX-License-Identifier: MIT

import InstanceFeature
import Neovim

public struct NimsState {
  public init(instanceState: InstanceState? = nil) {
    self.instanceState = instanceState
  }

  public var instanceState: InstanceState?
}
