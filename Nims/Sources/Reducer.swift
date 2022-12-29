// SPDX-License-Identifier: MIT

import CasePaths
import ComposableArchitecture
import Foundation
import IdentifiedCollections
import Instance
import Library
import Neovim

// MARK: - Action

enum Action: Sendable {
  case createInstance(arguments: [String], environmentOverlay: [String: String], keyPresses: AsyncStream<KeyPress>)
  case instance(action: Instance.Action)
}

// MARK: - Reducer

struct Reducer: ReducerProtocol {
  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case let .createInstance(arguments, environmentOverlay, keyPresses):
        let instanceID = Instance.State.ID(
          rawValue: UUID().uuidString
        )

        state.instance = .init(id: instanceID)

        return .run { send in
          let defaultFont = await Instance.State.Font(
            .monospacedSystemFont(ofSize: 12, weight: .regular)
          )
          await send(
            .instance(
              action: .setDefaultFont(defaultFont)
            )
          )

          await send(
            .instance(
              action: .createNeovimProcess(
                arguments: arguments,
                environmentOverlay: environmentOverlay,
                keyPresses: keyPresses
              )
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
