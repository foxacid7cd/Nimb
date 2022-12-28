// SPDX-License-Identifier: MIT

public struct Cell: Sendable, Equatable {
  public init(text: String, highlightID: Highlight.ID) {
    self.text = text
    self.highlightID = highlightID
  }

  public static let `default` = Self(
    text: " ",
    highlightID: .default
  )

  public var text: String
  public var highlightID: Highlight.ID
}
