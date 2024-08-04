// SPDX-License-Identifier: MIT

@PublicInit
public struct NeovimError: Error, Sendable {
  public var raw: Value
}
