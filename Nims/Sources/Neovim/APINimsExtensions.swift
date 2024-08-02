// SPDX-License-Identifier: MIT

import CasePaths
import Library
import MessagePack

public extension API {
  @discardableResult
  func nims(method: String, parameters: [Value] = []) async throws -> Value? {
    let rawResult = try await nvimExecLua(
      code: "return require('nims-gui').\(method)(\(parameters.isEmpty ? "" : "..."))",
      args: parameters
    )
    switch rawResult {
    case let .dictionary(dictionary):
      if 
        let rawFailure = dictionary["failure"],
        case let .array(rawErrorMessages) = rawFailure
      {
        throw NimsNeovimError(
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

  func nimsFast(method: String, parameters: [Value] = []) throws {
    try fastCall(APIFunctions.NvimExecLua(
      code: "return require('nims-gui').\(method)(\(parameters.isEmpty ? "" : "..."))",
      args: parameters
    ))
  }
}

@PublicInit
public struct NimsNeovimError: Error, Sendable {
  public var errorMessages: [String]
}
