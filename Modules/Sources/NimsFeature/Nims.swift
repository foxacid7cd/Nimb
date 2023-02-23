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
      environmentOverlay: [String: String],
      mouseEvents: AsyncStream<MouseEvent>,
      keyPresses: AsyncStream<KeyPress>
    )
    case instance(action: Instance.Action)
    case removeInstance
  }

  public var body: some ReducerProtocol<NimsState, Action> {
    Reduce { state, action in
      switch action {
      case let .createInstance(arguments, environmentOverlay, mouseEvents, keyPresses):
        let nsFont: NSFont
        if let jetBrains = NSFont(name: "JetBrainsMono Nerd Font Mono", size: 12) {
          nsFont = jetBrains

        } else {
          nsFont = .monospacedSystemFont(ofSize: 12, weight: .regular)
        }

        let process = Neovim.Process(
          arguments: arguments,
          environmentOverlay: environmentOverlay
        )
        state.instanceState = .init(
          process: process,
          font: .init(nsFont)
        )

        return .run { send in
          do {
            for try await processState in await process.states {
              switch processState {
              case .running:
                await send(
                  .instance(
                    action: .bindNeovimProcess(
                      mouseEvents: mouseEvents,
                      keyPresses: keyPresses
                    )
                  )
                )
              }
            }
          } catch {
            assertionFailure("\(error)")
          }

          await send(.removeInstance)
        }

      case .instance:
        return .none

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
