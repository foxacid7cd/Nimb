// SPDX-License-Identifier: MIT

import NimbCore

@PublicInit
public struct NeovimError: Error, Sendable {
  public var raw: Value
}
