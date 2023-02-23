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
  }

  public struct State {
    public init(instance: Instance.State? = nil) {
      self.instance = instance
    }

    public var instance: Instance.State?
  }

  public var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case let .createInstance(arguments, environmentOverlay):
        state.instance = Instance.State(
          process: nil,
          bufferedUIEvents: [],
          rawOptions: [:],
          font: .init(NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)),
          highlights: [],
          grids: [],
          windows: [],
          floatingWindows: [],
          cursorBlinkingPhase: true,
          windowZIndexCounter: 0,
          cmdlines: [],
          cmdlineUpdateFlag: false,
          instanceUpdateFlag: false,
          gridsLayoutUpdateFlag: false
        )

        return .run { send in
          await send(
            .instance(
              action: .createNeovimProcess(
                arguments: arguments,
                environmentOverlay: environmentOverlay
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
    .ifLet(\.instance, action: /Action.instance, then: {
      Instance()
    })
  }
}
