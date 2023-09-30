// SPDX-License-Identifier: MIT

import Library
import MessagePack

@PublicInit
public struct Popupmenu: Sendable, Hashable {
  public enum Anchor: Sendable, Hashable {
    case grid(id: Grid.ID, origin: IntegerPoint)
    case cmdline(location: Int)
  }

  public var items: [PopupmenuItem]
  public var selectedItemIndex: Int?
  public var anchor: Anchor
}

@PublicInit
public struct PopupmenuItem: Sendable, Hashable {
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

  public var word: String
  public var kind: String
  public var menu: String
  public var info: String
}
