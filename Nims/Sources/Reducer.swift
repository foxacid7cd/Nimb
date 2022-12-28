//
//  Reducer.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 16.12.2022.
//

import CasePaths
import ComposableArchitecture
import Foundation
import IdentifiedCollections
import Instance
import Library

enum Action: Sendable {
  case createInstance
  case instance(id: Instance.State.ID, action: Instance.Action)
}

struct Reducer: ReducerProtocol {
  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .createInstance:
        let instanceID = Instance.State.ID(
          rawValue: UUID().uuidString)

        state.instances.updateOrAppend(
          .init(
            id: instanceID))

        return .run { send in
          await send(
            .instance(
              id: instanceID,
              action: .startProcess))
        }

      case let .instance(id, action):
        switch action {
        case let .handleError(error):
          return .fireAndForget {
            assertionFailure("\(error)")
          }

        case let .processFinished(error):
          state.instances.remove(id: id)

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
    .forEach(\.instances, action: /Action.instance) {
      Instance.Reducer()
    }
  }
}
