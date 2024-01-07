// SPDX-License-Identifier: MIT

import CasePaths
import Library
import MessagePack

public enum UIEventsChunk: Sendable {
  case single(UIEvent)
  case gridLines(gridID: Grid.ID, hlAttrDefines: [HlAttrDefine], gridLines: IntKeyedDictionary<[GridLine]>)

  @PublicInit
  public struct HlAttrDefine: Sendable {
    public init(id: Int, rgbAttrs: [Value: Value], ctermAttrs: [Value: Value], rawInfo: [Value]) throws {
      self.id = id
      self.rgbAttrs = rgbAttrs
      self.ctermAttrs = ctermAttrs
      info = try rawInfo.map(HlAttrDefineInfoItem.init(raw:))
    }

    public var id: Int
    public var rgbAttrs: [Value: Value]
    public var ctermAttrs: [Value: Value]
    public var info: [HlAttrDefineInfoItem]
  }

  @PublicInit
  public struct HlAttrDefineInfoItem: Sendable {
    public init(raw: Value) throws {
      guard 
        case let .dictionary(raw) = raw,
        case let .string(kind) = raw["kind"],
        case let .integer(id) = raw["id"]
      else {
        throw Failure("invalid raw HlAttrDefineInfoItem value", raw)
      }
      self.init(
        kind: kind,
        hiName: raw["hi_name"].flatMap(/Value.string),
        uiName: raw["ui_name"].flatMap(/Value.string),
        id: id
      )
    }

    public var kind: String
    public var hiName: String?
    public var uiName: String?
    public var id: Int
  }

  @PublicInit
  public struct GridLine: Sendable {
    public var originColumn: Int
    public var data: [Value]
    public var wrap: Bool
  }
}
