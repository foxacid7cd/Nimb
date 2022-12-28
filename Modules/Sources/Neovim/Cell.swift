// SPDX-License-Identifier: MIT

public struct Cell: Sendable, Equatable {
  public init(text: String, highlightID: Highlight.ID) {
    self.text = text
    self.highlightID = highlightID
  }

  public var text: String
  public var highlightID: Highlight.ID
}
