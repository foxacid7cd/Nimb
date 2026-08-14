// SPDX-License-Identifier: MIT

import NimbCore
import NimbNeovim

/// Nonisolated: alerts are constructed inside the off-main state updates loop
/// and yielded to the main actor for presentation.
@PublicInit
public nonisolated struct Alert: Sendable, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
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
