// SPDX-License-Identifier: MIT

import AsyncAlgorithms
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

  public enum Action: Sendable {
    case createInstance(keyPresses: AsyncStream<KeyPress>)
    case instance(action: Instance.Action)
    case removeInstance
  }

  public var body: some ReducerProtocol<NimsState, Action> {
    Reduce { state, action in
      switch action {
      case let .createInstance(keyPresses):
        let nsFont: NSFont
        if let meslo = NSFont(name: "SFMono Nerd Font Mono", size: 12) {
          nsFont = meslo

        } else {
          nsFont = .monospacedSystemFont(ofSize: 12, weight: .regular)
        }

        let process = Neovim.Process(
          arguments: ["-u", "/Users/foxacid/.local/share/lunarvim/lvim/init.lua"],
          environmentOverlay: [
            "LUNARVIM_RUNTIME_DIR": "/Users/foxacid/.local/share/lunarvim",
            "LUNARVIM_CONFIG_DIR": "/Users/foxacid/.config/lvim",
            "LUNARVIM_CACHE_DIR": "/Users/foxacid/.cache/lvim",
            "LUNARVIM_BASE_DIR": "/Users/foxacid/.local/share/lunarvim/lvim",
          ]
        )

        let (sendMouseEvent, mouseEvents) = AsyncChannel<MouseEvent>.pipe()
        state.instanceState = .init(
          process: process,
          font: .init(nsFont),
          reportMouseEvent: { mouseEvent in
            Task {
              await sendMouseEvent(mouseEvent)
            }
          }
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
