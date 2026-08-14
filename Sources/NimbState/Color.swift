// SPDX-License-Identifier: MIT

import AppKit
import NimbCore
import SwiftUI

@PublicInit
public struct Color: Sendable, Hashable {
  public static let black = Color(rgb: 0)

  public var rgb: Int
  public var alpha: Double = 1

  public var swiftUI: SwiftUI.Color {
    .init(red: red, green: green, blue: blue).opacity(alpha)
  }

  public var appKit: NSColor {
    NSColor(deviceRed: red, green: green, blue: blue, alpha: alpha)
  }

  public var cg: CGColor {
    appKit.cgColor
  }

  public var red: Double {
    Double((rgb >> 16) & 0xFF) / 255
  }

  public var green: Double {
    Double((rgb >> 8) & 0xFF) / 255
  }

  public var blue: Double {
    Double(rgb & 0xFF) / 255
  }

  public func with(alpha: Double) -> Color {
    var copy = self
    copy.alpha = alpha
    return copy
  }
}
