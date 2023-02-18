// SPDX-License-Identifier: MIT

import CasePaths
import ComposableArchitecture
import Foundation
import IdentifiedCollections
import InstanceFeature
import Library
import Neovim

public struct Nims: ReducerProtocol {
  public init() {}

  public enum Action {
    case createInstance(
      arguments: [String],
      environmentOverlay: [String: String],
      keyPresses: AsyncStream<KeyPress>,
      mouseEvents: AsyncStream<MouseEvent>
    )
    case instance(action: Instance.Action)
  }

  public struct State: Equatable {
    public init(instance: Instance.State? = nil) {
      self.instance = instance
    }

    public var instance: Instance.State?
  }

  public var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case let .createInstance(arguments, environmentOverlay, keyPresses, mouseEvents):
        state.instance = .init()

        return .run { send in
          let defaultFont = await InstanceFeature.Font(
            .init(name: "JetBrainsMono Nerd Font Mono", size: 12)!
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
                keyPresses: keyPresses,
                mouseEvents: mouseEvents
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
    .ifLet(\.instance, action: /Action.instance, then: { Instance() })
  }
}
