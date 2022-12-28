// SPDX-License-Identifier: MIT

import AppKit
import CasePaths
import ComposableArchitecture
import IdentifiedCollections
import Instance
import Library
import Neovim

enum Action: Sendable {
  case createInstance(keyPresses: AsyncStream<KeyPress>)
  case instance(action: Instance.Action)
}

struct Reducer: ReducerProtocol {
  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case let .createInstance(keyPresses):
        let instanceID = Instance.State.ID(
          rawValue: UUID().uuidString
        )

        state.instance = .init(id: instanceID)

        return .run { send in
          await send(
            .instance(
              action: .createProcess(keyPresses: keyPresses)
            )
          )
        }

      case let .instance(action):
        switch action {
        case let .handleError(error):
          return .fireAndForget {
            assertionFailure("\(error)")
          }

        case let .processFinished(error):
          state.instance = nil

          return .fireAndForget {
            if let error {
              assertionFailure("\(error)")
            }

            NSApplication.shared.terminate(nil)
          }

        default:
          return .none
        }
      }
    }
    .ifLet(
      \.instance, action: /Action.instance,
      then: {
        Instance.Reducer()
      }
    )
  }
}
