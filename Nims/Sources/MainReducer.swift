// SPDX-License-Identifier: MIT

import CasePaths
import ComposableArchitecture
import Library
import Neovim

struct MainReducer: Reducer {
  struct State {
    var instances: IdentifiedArrayOf<InstanceReducer.State> = []
  }

  enum Action {
    case createNeovimInstance(
      keyPresses: AsyncStream<KeyPress>,
      mouseEvents: AsyncStream<MouseEvent>
    )
    case instance(id: InstanceReducer.State.ID, action: InstanceReducer.Action)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .createNeovimInstance(keyPresses, mouseEvents):
        let id = InstanceReducer.State.ID(state.instances.count)
        state.instances.updateOrAppend(.init(id: id))

        return .run { send in
          await send(
            .instance(
              id: id,
              action: .start(
                keyPresses: keyPresses,
                mouseEvents: mouseEvents
              )
            )
          )
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
