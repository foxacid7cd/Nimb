//
//  File.swift
//  
//
//  Created by Yevhenii Matviienko on 28.02.2023.
//

import Tagged

public struct Cmdline: Identifiable, Sendable {
  public var contentParts: [ContentPart]
  public var cursorPosition: Int
  public var firstCharacter: String
  public var prompt: String
  public var indent: Int
  public var level: Int
  public var specialCharacter: String
  public var shiftAfterSpecialCharacter: Bool
  public var blockLines: [[ContentPart]]

  public struct ContentPart: Sendable {
    public var highlightID: Highlight.ID
    public var text: String
  }

  public var id: Int {
    level
  }
}
