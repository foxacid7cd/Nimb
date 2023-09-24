// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import CasePaths
import ComposableArchitecture
import CustomDump
import Library
import Neovim

public struct RunningInstanceReducer: Reducer {
  public struct State: Sendable {
    public let instance: Neovim.Instance
  }

  public enum Action: Sendable {
    case sideMenuButtonPressed
    case reportSelectedTabpage(id: Tabpage.ID)
  }

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    .none
  }
}
