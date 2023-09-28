// SPDX-License-Identifier: MIT

import IdentifiedCollections
import Library
import Tagged

@PublicInit
public struct Tabline: Sendable, Hashable {
  public var currentTabpageID: Tabpage.ID
  public var tabpages: IdentifiedArrayOf<Tabpage>
  public var currentBufferID: Buffer.ID
  public var buffers: IdentifiedArrayOf<Buffer>
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
