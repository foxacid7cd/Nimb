// SPDX-License-Identifier: MIT

import CasePaths

public extension API {
  @discardableResult
  func nimb(method: String, parameters: [Value] = []) async throws -> Value? {
    let rawResult = try await nvimExecLua(
      code: "return require('nimb-gui').\(method)(\(parameters.isEmpty ? "" : "..."))",
      args: parameters
    )
    switch rawResult {
    case let .dictionary(dictionary):
      if 
        let rawFailure = dictionary["failure"],
        case let .array(rawErrorMessages) = rawFailure
      {
        throw NimbNeovimError(
          errorMessages: rawErrorMessages.compactMap(\.string)
        )
      } else if let rawSuccess = dictionary["success"] {
        return rawSuccess
      }

    default:
      break
    }
    return nil
  }

  @MainActor
  func nimbFast(method: String, parameters: [Value] = []) throws {
    try fastCall(APIFunctions.NvimExecLua(
      code: "return require('nimb-gui').\(method)(\(parameters.isEmpty ? "" : "..."))",
      args: parameters
    ))
  }
}

@PublicInit
public struct NimbNeovimError: Error, Sendable {
  public var errorMessages: [String]
}
