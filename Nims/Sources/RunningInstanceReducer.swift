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

    public var appearance = Appearance()
    public var appearanceUpdateFlag = false

    public var cmdlines = IntKeyedDictionary<Cmdline>()
    public var cmdlinesUpdateFlag = false
  }

  public enum Action: Sendable {
    case setTitle(String?)
    case setOuterGridSize(IntegerSize?)
    case setAppearance(Appearance)
    case setCmdlines(IntKeyedDictionary<Cmdline>)
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

    case let .setAppearance(value):
      state.appearance = value
      state.appearanceUpdateFlag.toggle()

      return .none

    case let .setCmdlines(value):
      state.cmdlines = value
      state.cmdlinesUpdateFlag.toggle()

      return .none
    }
  }
}
