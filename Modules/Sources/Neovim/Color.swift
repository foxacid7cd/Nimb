// SPDX-License-Identifier: MIT

import AppKit
import Library
import SwiftUI

@PublicInit
public struct Color: Sendable, Hashable {
  public var rgb: Int
  public var alpha: Double = 1

  public func with(alpha: Double) -> Color {
    var copy = self
    copy.alpha = alpha
    return copy
  }

  public var swiftUI: SwiftUI.Color {
    .init(
      .displayP3,
      red: red,
      green: green,
      blue: blue
    )
    .opacity(alpha)
  }

  public var appKit: NSColor {
    .init(
      displayP3Red: red,
      green: green,
      blue: blue,
      alpha: alpha
    )
  }

  public static let black = Color(rgb: 0)

  private var red: Double {
    Double((rgb >> 16) & 0xFF) / 255
  }

  private var green: Double {
    Double((rgb >> 8) & 0xFF) / 255
  }

  private var blue: Double {
    Double(rgb & 0xFF) / 255
  }
}
