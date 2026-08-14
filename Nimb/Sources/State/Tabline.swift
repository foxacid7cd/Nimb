// SPDX-License-Identifier: MIT

import NimbCore

@PublicInit
public struct Tabline: Sendable, Hashable {
  public var currentTabpageID: Tabpage.ID
  public var tabpages: [Tabpage]
  public var currentBufferID: Buffer.ID
  public var buffers: [Buffer]
}

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
