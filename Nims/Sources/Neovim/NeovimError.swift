// SPDX-License-Identifier: MIT

import Library
import MessagePack

@PublicInit
public struct NeovimError: Error, Sendable {
  public var raw: Value
}
