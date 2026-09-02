// SPDX-License-Identifier: MIT

import NimbCore

public extension API {
  @discardableResult
  func nimb(method: String, parameters: [Value] = []) async throws -> Value? {
    let rawResult = try await nvimExecLua(
      code: "return require('nimb-gui').\(method)(\(parameters.isEmpty ? "" : "..."))",
      args: parameters,
    )
    switch rawResult {
    case let .dictionary(dictionary):
      if
        let rawFailure = dictionary["failure"],
        case let .array(rawErrorMessages) = rawFailure
      {
        throw NimbNeovimError(
          errorMessages: rawErrorMessages.compactMap(\.string),
        )
      } else if let rawSuccess = dictionary["success"] {
        return rawSuccess
      }

    default:
      break
    }
    return nil
  }

  func nimbFast(method: String, parameters: [Value] = []) {
    fastCall(APIFunctions.NvimExecLua(
      code: "return require('nimb-gui').\(method)(\(parameters.isEmpty ? "" : "..."))",
      args: parameters,
    ))
  }

  func keyPressed(_ keyPress: KeyPress) {
    fastCall(APIFunctions.NvimInput(keys: keyPress.makeNvimKeyCode()))
  }

  func scrollWindow(_ windowID: References.Window, toTopLine topLine: Int) {
    nimbFast(
      method: "scroll_window",
      parameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .integer(topLine),
      ],
    )
  }
}

@PublicInit
public struct NimbNeovimError: Error, Sendable {
  public var errorMessages: [String]
}
