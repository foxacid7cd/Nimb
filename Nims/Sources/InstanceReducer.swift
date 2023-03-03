// SPDX-License-Identifier: MIT

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

    public typealias ID = Tagged<Self, Int>

    public enum Phase: Sendable {
      case pending
      case running(Running)
      case finished(message: String)

      public struct Running: Sendable {
        public let stateContainer: Neovim.Instance.StateContainer
        public var title: String?
        public var updateFlag = false
      }
    }
  }

  public enum Action: Sendable {
    case start
    case started(Neovim.Instance.StateContainer)
    case finished(Error?)
    case phase(Phase)

    public enum Phase: Sendable {
      case pending(Pending)
      case running(Running)
      case finished(Finished)

      public enum Pending: Sendable {}

      public enum Running: Sendable {
        case setTitle(String?)
      }

      public enum Finished: Sendable {
        case close
      }
    }
  }

  public var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .start:
        guard case .pending = state.phase else {
          return .none
        }

        return .run { @MainActor send in
          let instance = Neovim.Instance()

          send(.started(instance.stateContainer))

          do {
            for try await element in instance {
              switch element {
              case let .stateUpdates(value):
                let state = instance.stateContainer.state

                if value.isTitleUpdated {
                  send(
                    .phase(
                      .running(
                        .setTitle(state.title)
                      )
                    )
                  )
                }
              }
            }

            send(.finished(nil))

          } catch {
            send(.finished(error))
          }
        }

      case let .started(stateContainer):
        state.phase = .running(
          .init(stateContainer: stateContainer)
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
          }

        default:
          break
        }

        return .none
      }
    }
    Scope(state: \.phase, action: /Action.phase) {
      EmptyReducer()
        .ifCaseLet(/State.Phase.running, action: /Action.Phase.running) {
          Reduce<State.Phase.Running, Action.Phase.Running> { state, action in
            switch action {
            case let .setTitle(title):
              state.title = title
              state.updateFlag.toggle()

              return .none
            }
          }
        }
    }
  }
}
