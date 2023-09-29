// SPDX-License-Identifier: MIT

import Library

@PublicInit
public struct Cmdlines: Sendable {
  public var dictionary: IntKeyedDictionary<Cmdline> = [:]
  public var blockLines: IntKeyedDictionary<[[Cmdline.ContentPart]]> = [:]
  public var lastCmdlineLevel: Int? = nil
}

@PublicInit
public struct Cmdline: Identifiable, Sendable, Equatable, Hashable {
  public var contentParts: [ContentPart]
  public var cursorPosition: Int
  public var firstCharacter: String
  public var prompt: String
  public var indent: Int
  public var level: Int
  public var specialCharacter: String
  public var shiftAfterSpecialCharacter: Bool

  @PublicInit
  public struct ContentPart: Sendable, Equatable, Hashable {
    public var highlightID: Highlight.ID
    public var text: String
  }

  public var id: Int {
    level
  }
}
