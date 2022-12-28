// SPDX-License-Identifier: MIT

public struct Color: Sendable, Equatable {
  public init(
    rgb: Int,
    opacity: Double = 1
  ) {
    self.rgb = rgb
    self.opacity = opacity
  }

  public var rgb: Int
  public var opacity: Double
}
