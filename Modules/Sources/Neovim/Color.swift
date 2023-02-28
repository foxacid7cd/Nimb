// SPDX-License-Identifier: MIT

import AppKit
import SwiftUI

public struct Color: Sendable, Hashable {
  public init(rgb: Int) {
    self.rgb = rgb
  }

  public var rgb: Int

  public var swiftUI: SwiftUI.Color {
    .init(
      .displayP3,
      red: red,
      green: green,
      blue: blue
    )
  }

  public var appKit: NSColor {
    .init(
      red: red,
      green: green,
      blue: blue,
      alpha: 1
    )
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
