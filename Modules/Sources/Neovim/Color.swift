//
//  Color.swift
//
//
//  Created by Yevhenii Matviienko on 27.12.2022.
//

public struct Color: Sendable, Equatable {
  public var rgb: Int
  public var opacity: Double

  public init(
    rgb: Int,
    opacity: Double = 1
  ) {
    self.rgb = rgb
    self.opacity = opacity
  }
}
