// SPDX-License-Identifier: MIT

import InstanceFeature
import Library
import Neovim

public struct NimsState {
  public init(reportMouseEvent: @escaping (MouseEvent) -> Void, instanceState: InstanceState? = nil) {
    self.reportMouseEvent = reportMouseEvent
    self.instanceState = instanceState
  }

  public var reportMouseEvent: (MouseEvent) -> Void
  public var instanceState: InstanceState?
}
