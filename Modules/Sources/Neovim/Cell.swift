//
//  Cell.swift
//
//
//  Created by Yevhenii Matviienko on 27.12.2022.
//

public struct Cell: Sendable, Equatable {
  public var text: String
  public var highlightID: Highlight.ID

  public init(text: String, highlightID: Highlight.ID) {
    self.text = text
    self.highlightID = highlightID
  }
}
