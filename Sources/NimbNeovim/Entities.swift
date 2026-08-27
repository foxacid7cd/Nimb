// SPDX-License-Identifier: MIT

import NimbCore

/// Neovim object handles carrying their display name. Here rather than with
/// the application state, since the generated API signatures refer to them.
@PublicInit
public struct Tabpage: Identifiable, Sendable, Hashable {
  public var id: References.Tabpage
  public var name: String
}

@PublicInit
public struct Buffer: Identifiable, Sendable, Hashable {
  public var id: References.Buffer
  public var name: String
}

@PublicInit
public struct Window: Sendable, Identifiable {
  public var id: References.Window
  public var origin: IntegerPoint
  public var size: IntegerSize
}
