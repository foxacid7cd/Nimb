// SPDX-License-Identifier: MIT

import MessagePack

public enum UIEventsChunk {
  case single(UIEvent)
  case gridLines(gridID: Grid.ID, gridLines: [GridLine])

  public struct GridLine {
    var row: Int
    var originColumn: Int
    var data: [Value]
    var wrap: Bool
  }
}
