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

  func nimbFast(method: String, parameters: [Value] = []) throws {
    try fastCall(APIFunctions.NvimExecLua(
      code: "return require('nimb-gui').\(method)(\(parameters.isEmpty ? "" : "..."))",
      args: parameters
    ))
  }

  func keyPressed(_ keyPress: KeyPress) throws {
    try fastCall(APIFunctions.NvimInput(keys: keyPress.makeNvimKeyCode()))
  }
}

@PublicInit
public struct NimbNeovimError: Error, Sendable {
  public var errorMessages: [String]
}
