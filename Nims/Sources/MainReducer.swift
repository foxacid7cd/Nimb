// SPDX-License-Identifier: MIT

import CasePaths
import ComposableArchitecture
import Library
import Neovim

struct MainReducer: ReducerProtocol {
  struct State {
    var instances: IdentifiedArrayOf<InstanceReducer.State> = []
  }

  enum Action {
    case createNeovimInstance
    case instance(id: InstanceReducer.State.ID, action: InstanceReducer.Action)
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .createNeovimInstance:
        let id = InstanceReducer.State.ID(state.instances.count)
        state.instances.updateOrAppend(.init(id: id))

        return .task {
          .instance(id: id, action: .start)
        }

      default:
        return .none
      }
    }
    .forEach(\.instances, action: /Action.instance(id:action:)) {
      InstanceReducer()
    }
  }
}
