// SPDX-License-Identifier: MIT

import IdentifiedCollections
import Tagged

public struct Tabpage: Identifiable, Sendable {
  public var id: ID
  public var name: String

  public typealias ID = Tagged<Self, References.Tabpage>
}

public struct Tabline: Sendable {
  public var currentTabpageID: Tabpage.ID
  public var tabpages: IdentifiedArrayOf<Tabpage>
}
