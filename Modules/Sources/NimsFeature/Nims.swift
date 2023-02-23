// SPDX-License-Identifier: MIT

import CasePaths
import ComposableArchitecture
import Foundation
import IdentifiedCollections
import InstanceFeature
import Library
import Neovim
import SwiftUI

public struct Nims: ReducerProtocol {
  public init() {}

  public enum Action {
    case createInstance(
      arguments: [String],
      environmentOverlay: [String: String]
    )
    case instance(action: Instance.Action)
    case removeInstance
  }

  public var body: some ReducerProtocol<NimsState, Action> {
    Reduce { state, action in
      switch action {
      case let .createInstance(arguments, environmentOverlay):
        let process = Neovim.Process(
          arguments: arguments,
          environmentOverlay: environmentOverlay
        )
        state.instanceState = .init(process: process)

        return .run { send in
          do {
            for try await processState in await process.states {
              switch processState {
              case .running:
                await send(.instance(action: .bindNeovimProcess))
              }
            }
          } catch {
            assertionFailure("\(error)")
          }

          await send(.removeInstance)
        }

      case let .instance(action):
        switch action {
        case let .handleError(error):
          return .fireAndForget {
            assertionFailure("\(error)")
          }

        case let .processFinished(error):
          state.instanceState = nil

          return .fireAndForget {
            if let error {
              assertionFailure("\(error)")
            }
          }

        default:
          return .none
        }

      case .removeInstance:
        state.instanceState = nil

        return .none
      }
    }
    .ifLet(\.instanceState, action: /Action.instance, then: {
      Instance()
    })
  }
}
