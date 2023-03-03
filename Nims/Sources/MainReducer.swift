// SPDX-License-Identifier: MIT

import ComposableArchitecture
import Neovim

struct MainReducer: ReducerProtocol {
  struct State {
    enum Instance {
      case created
      case running(stateContainer: Neovim.Instance.StateContainer)
      case finished(error: Error?)
    }

    var instance: Instance?
    var instanceUpdateFlag = false
  }

  enum Action {
    case createNeovimInstance
    case instanceRunning(stateContainer: Neovim.Instance.StateContainer)
    case instanceFinished(error: Error?)
  }

  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .createNeovimInstance:
      state.instance = .created
      state.instanceUpdateFlag.toggle()

      let task = EffectTask<Action>.run { send in
        let instance = Instance()

        await send(.instanceRunning(stateContainer: instance.stateContainer))

        do {
          for try await element in instance {
            switch element {
            case let .stateUpdates(value):
              customDump(value)
            }
          }

          await send(.instanceFinished(error: nil))

        } catch {
          await send(.instanceFinished(error: error))
        }
      }

      return task

    case let .instanceRunning(stateContainer):
      state.instance = .running(stateContainer: stateContainer)
      state.instanceUpdateFlag.toggle()

      return .none

    case let .instanceFinished(error):
      state.instance = .finished(error: error)
      state.instanceUpdateFlag.toggle()

      return .none
    }
  }
}
