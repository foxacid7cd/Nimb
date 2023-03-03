// SPDX-License-Identifier: MIT

import CasePaths
import ComposableArchitecture
import CustomDump
import Library
import Neovim

public struct RunningInstanceReducer: ReducerProtocol {
  public struct State: Sendable {
    public let stateContainer: Neovim.Instance.StateContainer

    public var title: String?
    public var titleUpdateFlag = false

    public var outerGridSize: IntegerSize?
    public var outerGridSizeUpdateFlag = false
  }

  public enum Action: Sendable {
    case setTitle(String?)
    case setOuterGridSize(IntegerSize?)
  }

  public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case let .setTitle(value):
      state.title = value
      state.titleUpdateFlag.toggle()

      return .none

    case let .setOuterGridSize(value):
      state.outerGridSize = value
      state.outerGridSizeUpdateFlag.toggle()

      return .none
    }
  }
}
