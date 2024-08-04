// SPDX-License-Identifier: MIT

@PublicInit
public struct NeovimErrorEvent: Sendable, Equatable {
  public init(parameters: [Value]) throws {
    guard
      parameters.count >= 2, let error = parameters[0].integer.flatMap(
        APIError.init(rawValue:)
      ),
      let message = parameters[1].string
    else {
      throw Failure(
        "Invalid nvim_error_event notification parameters",
        parameters
      )
    }
    self.init(error: error, message: message)
  }

  public var error: APIError
  public var message: String
}
