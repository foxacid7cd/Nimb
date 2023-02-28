//
//  File.swift
//  
//
//  Created by Yevhenii Matviienko on 28.02.2023.
//

import IdentifiedCollections
import Tagged

public struct Tab: Identifiable, Sendable {
  public var id: References.Tabpage
  public var name: String
}

public struct Tabline: Sendable {
  public var currentTabID: Tab.ID
  public var tabs: IdentifiedArrayOf<Tab>
}
