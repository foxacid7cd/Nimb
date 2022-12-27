//
//  Highlight.swift
//
//
//  Created by Yevhenii Matviienko on 27.12.2022.
//

import Tagged

public struct Highlight: Sendable, Equatable, Identifiable {
  public var id: ID

  public init(id: ID) {
    self.id = id
  }

  public typealias ID = Tagged<Highlight, Int>
}

extension Highlight.ID {
  public static var `default`: Self {
    0
  }

  public var isDefault: Bool {
    self == .default
  }
}
