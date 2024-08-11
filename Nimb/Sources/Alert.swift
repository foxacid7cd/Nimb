// SPDX-License-Identifier: MIT

@PublicInit
public struct Alert: Sendable, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
  public var message: String

  public init(stringLiteral value: StringLiteralType) {
    self.init(message: value)
  }

  public init(_ error: Error) {
    message =
      if let error = error as? NimbNeovimError {
        error.errorMessages.joined(separator: "\n")
      } else if let error = error as? NeovimError {
        String(customDumping: error.raw)
      } else {
        String(customDumping: error)
      }
  }
}
