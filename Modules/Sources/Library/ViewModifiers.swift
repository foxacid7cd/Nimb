// SPDX-License-Identifier: MIT

import AppKit
import SwiftUI

public extension View {
  func frame(size: CGSize, alignment: Alignment) -> some View {
    frame(width: size.width, height: size.height, alignment: alignment)
  }

  func offset(_ point: CGPoint) -> some View {
    offset(x: point.x, y: point.y)
  }
}
