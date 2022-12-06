// Copyright © 2022 foxacid7cd. All rights reserved.

import CasePaths
import MessagePack

public actor API {
  public init(_ channel: some Channel) {
    let rpc = RPC(channel)
    self.rpc = rpc

    task = Task {
      for try await notification in await rpc.notifications {
        switch notification.method {
        case "redraw":
          for parameter in notification.parameters {
            guard
              let array = (/Value.array).extract(from: parameter),
              !array.isEmpty,
              let uiEventName = (/Value.string).extract(from: array[0])
            else {
              assertionFailure()
              continue
            }

            print(uiEventName)
          }

        default:
          break
        }
      }
    }
  }

  public let task: Task<Void, Error>

  func call<Success>(
    method: String,
    withParameters parameters: [Value],
    assumingSuccessType successType: Success.Type
  ) async throws -> Result<Success, RemoteError> {
    try await rpc.call(method: method, withParameters: parameters)
      .map { success in
        guard let success = success as? Success else {
          preconditionFailure("Assumed success response type does not match returned response type")
        }

        return success
      }
  }

  private let rpc: RPC
}
