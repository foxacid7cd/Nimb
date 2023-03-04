// SPDX-License-Identifier: MIT

import Tagged

public struct MsgShow: Identifiable, Sendable {
  public var index: Int
  public var kind: String
  public var contentParts: [ContentPart]

  public struct ContentPart: Sendable {
    public var highlightID: Highlight.ID
    public var text: String
  }

  public var id: Int {
    index
  }
}
