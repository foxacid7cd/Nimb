// SPDX-License-Identifier: MIT

import AppKit
import CasePaths
import ComposableArchitecture
import CustomDump
import Neovim
import Tagged

public struct InstanceReducer: ReducerProtocol {
  public struct State: Sendable, Identifiable {
    public let id: ID
    public var phase = Phase.pending
    public var phaseUpdateFlag = false
    public var font = NimsFont()
    public var fontUpdateFlag = false

    public typealias ID = Tagged<Self, Int>

    public enum Phase: Sendable {
      case pending
      case running(RunningInstanceReducer.State)
      case finished(message: String)
    }
  }

  public enum Action: Sendable {
    case setFont(NimsFont)
    case start(keyPresses: AsyncStream<KeyPress>, mouseEvents: AsyncStream<MouseEvent>)
    case started(Instance)
    case finished(Error?)
    case phase(Phase)

    public enum Phase: Sendable {
      case pending(Pending)
      case running(RunningInstanceReducer.Action)
      case finished(Finished)

      public enum Pending: Sendable {}

      public enum Finished: Sendable {
        case close
      }
    }
  }

  public var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case let .setFont(font):
        state.font = font
        state.fontUpdateFlag.toggle()

        return .none

      case let .start(keyPresses, mouseEvents):
        guard case .pending = state.phase else {
          return .none
        }

        return EffectTask<Action>.run { @MainActor send in
          if let sfMonoNFM = NSFont(name: "SFMono Nerd Font Mono", size: 12) {
            let font = NimsFont(sfMonoNFM)
            send(.setFont(font))
          }

          send(.finished(nil))
        }

      case let .started(instance):
        state.phase = .running(
          .init(instance: instance)
        )
        state.phaseUpdateFlag.toggle()

        return .none

      case let .finished(error):
        let message: String
        if let error {
          var description = ""
          customDump(error, to: &description)

          message = "Error: \(description)"

        } else {
          message = "Success!"
        }

        state.phase = .finished(message: message)
        state.phaseUpdateFlag.toggle()

        return .none

      case let .phase(action):
        switch action {
        case let .finished(action):
          switch action {
          case .close:
            state.phase = .pending
            state.phaseUpdateFlag.toggle()

            return .none
          }

        default:
          return .none
        }
      }
    }
    Scope(state: \.phase, action: /Action.phase) {
      EmptyReducer()
        .ifCaseLet(/State.Phase.running, action: /Action.Phase.running) {
          RunningInstanceReducer()
        }
    }
  }
}
