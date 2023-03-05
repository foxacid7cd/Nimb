// SPDX-License-Identifier: MIT

import Tagged

public struct Cmdline: Identifiable, Sendable, Hashable {
  public var contentParts: [ContentPart]
  public var cursorPosition: Int
  public var firstCharacter: String
  public var prompt: String
  public var indent: Int
  public var level: Int
  public var specialCharacter: String
  public var shiftAfterSpecialCharacter: Bool
  public var blockLines: [[ContentPart]]

  public struct ContentPart: Sendable, Hashable {
    public var highlightID: Highlight.ID
    public var text: String
  }

  public var id: Int {
    level
  }
}
