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

    public var tabline: Tabline?
    public var tablineUpdateFlag = false

    public var cmdlines = IntKeyedDictionary<Cmdline>()
    public var cmdlinesUpdateFlag = false

    public var msgShows = IntKeyedDictionary<MsgShow>()
    public var msgShowsUpdateFlag = false
  }

  public enum Action: Sendable {
    case setTitle(String?)
    case setOuterGridSize(IntegerSize?)
    case setAppearance(Appearance)
    case setTabline(Tabline?)
    case setCmdlines(IntKeyedDictionary<Cmdline>)
    case setMsgShows(IntKeyedDictionary<MsgShow>)
    case sideMenuButtonPressed
    case reportSelectedTabpage(id: Tabpage.ID)
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

    case let .setTabline(value):
      state.tabline = value
      state.tablineUpdateFlag.toggle()

      return .none

    case let .setCmdlines(value):
      state.cmdlines = value
      state.cmdlinesUpdateFlag.toggle()

      return .none

    case let .setMsgShows(value):
      state.msgShows = value
      state.msgShowsUpdateFlag.toggle()

      return .none

    default:
      return .none
    }
  }
}