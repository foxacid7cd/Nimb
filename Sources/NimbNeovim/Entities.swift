// SPDX-License-Identifier: MIT

import NimbCore

/// Neovim object handles carrying their display name.
///
/// These live here rather than with the application state because the
/// generated API signatures refer to `Buffer.ID`, `Window.ID` and
/// `Tabpage.ID`, so they have to be visible to the bindings.
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
