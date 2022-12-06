// Copyright © 2022 foxacid7cd. All rights reserved.

import MessagePack

public actor API {
  public init(_ channel: some Channel) {
    let rpc = RPC(channel)
    self.rpc = rpc

    runTask = Task {
      for try await notification in await rpc.notifications {
        switch notification.method {
        case "redraw":
          for parameter in notification.parameters {
            guard
              let arrayValue = parameter as? [MessageValue],
              !arrayValue.isEmpty,
              let uiEventName = arrayValue[0] as? String
            else {
              assertionFailure()
              continue
            }
          }
          
        default:
          break
        }
      }
    }
  }

  func call<Success>(
    method: String,
    withParameters parameters: [MessageValue],
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

  private let runTask: Task<Void, Error>
  private let rpc: RPC
}
