// SPDX-License-Identifier: MIT

import AppKit
import Library
import SwiftUI

@PublicInit
public struct NimsColor: Sendable, Hashable {
  public static let black = NimsColor(rgb: 0)

  public var rgb: Int
  public var alpha: Double = 1

  public var swiftUI: SwiftUI.Color {
    .init(
      .sRGB,
      red: red,
      green: green,
      blue: blue
    )
    .opacity(alpha)
  }

  public var appKit: NSColor {
    .init(
      red: red,
      green: green,
      blue: blue,
      alpha: alpha
    )
  }

  public func with(alpha: Double) -> NimsColor {
    var copy = self
    copy.alpha = alpha
    return copy
  }

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