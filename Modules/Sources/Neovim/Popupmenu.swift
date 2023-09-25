// SPDX-License-Identifier: MIT

import MessagePack

public struct Popupmenu: Sendable, Hashable {
  public var items: [PopupmenuItem]
  public var selected: Int
  public var row: Int
  public var col: Int
  public var gridID: Grid.ID
}

public struct PopupmenuItem: Sendable, Hashable {
  public var word: String
  public var kind: String
  public var menu: String
  public var info: String
}

public extension PopupmenuItem {
  init?(rawItem: Value) {
    guard
      case let .array(rawItem) = rawItem,
      rawItem.count == 4,
      case let .string(word) = rawItem[0],
      case let .string(kind) = rawItem[1],
      case let .string(menu) = rawItem[2],
      case let .string(info) = rawItem[3]
    else {
      return nil
    }

    self.init(word: word, kind: kind, menu: menu, info: info)
  }
}
