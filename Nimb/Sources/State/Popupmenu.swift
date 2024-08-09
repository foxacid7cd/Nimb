// SPDX-License-Identifier: MIT

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
  public var word: String
  public var kind: String
  public var menu: String
  public var info: String

  public init(raw: Value) throws {
    guard
      case let .array(raw) = raw,
      raw.count == 4,
      case let .string(word) = raw[0],
      case let .string(kind) = raw[1],
      case let .string(menu) = raw[2],
      case let .string(info) = raw[3]
    else {
      throw Failure("invalid raw popupmenu item", raw)
    }

    self.init(word: word, kind: kind, menu: menu, info: info)
  }
}
