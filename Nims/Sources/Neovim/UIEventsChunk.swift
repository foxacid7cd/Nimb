// SPDX-License-Identifier: MIT

import Library
import MessagePack

public enum UIEventsChunk: Sendable {
  case single(UIEvent)
  case gridLines(gridID: Grid.ID, hlAttrDefines: [HlAttrDefine], gridLines: IntKeyedDictionary<[GridLine]>)

  public struct HlAttrDefine: Sendable {
    var id: Int
    var rgbAttrs: [Value: Value]
  }

  public struct GridLine: Sendable {
    var originColumn: Int
    var data: [Value]
    var wrap: Bool
  }
}
