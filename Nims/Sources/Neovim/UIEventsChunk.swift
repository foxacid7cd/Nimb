// SPDX-License-Identifier: MIT

import Library
import MessagePack

public enum UIEventsChunk: Sendable {
  case single(UIEvent)
  case gridLines(gridID: Grid.ID, gridLines: [GridLine])

  public struct GridLine: Sendable {
    var row: Int
    var originColumn: Int
    var data: [Value]
    var wrap: Bool
  }
}
