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
          errorMessages: rawErrorMessages.compactMap(/Value.string)
        )
      } else if let rawSuccess = dictionary["success"] {
        return rawSuccess
      }
    default:
      break
    }
    return nil
  }
}

@PublicInit
public struct NimsNeovimError: Error, Sendable {
  public var errorMessages: [String]
}
