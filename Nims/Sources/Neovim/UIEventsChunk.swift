// SPDX-License-Identifier: MIT

import Library
import MessagePack

public enum UIEventsChunk: Sendable {
  case single(UIEvent)
  case gridLines(gridID: Grid.ID, gridLines: IntKeyedDictionary<[GridLine]>)

  public struct GridLine: Sendable {
    var originColumn: Int
    var data: [Value]
    var wrap: Bool
  }
}
