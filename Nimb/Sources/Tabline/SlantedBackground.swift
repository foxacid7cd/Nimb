// SPDX-License-Identifier: MIT

import AppKit

// enum SlantedBackgroundImageType {
//  case background(isFlatLeft: Bool, isFlatRight: Bool)
//  case mask
// }

enum SlantedBackgroundFill {
  case gradient(from: NSColor, to: NSColor)
  case color(NSColor)
}

extension NSImage {
  static func makeSlantedBackground(
    isFlatLeft: Bool = false,
    isFlatRight: Bool = false,
    size: CGSize,
    fill: SlantedBackgroundFill
  )
    -> NSImage
  {
    .init(size: .init(width: size.width + 24, height: size.height), flipped: false) { _ in
      guard let graphicsContext = NSGraphicsContext.current else {
        return false
      }
      let cgContext = graphicsContext.cgContext

      cgContext.beginPath()
      cgContext.move(to: .init())
      cgContext.addLine(to: .init(x: isFlatLeft ? 0 : 12, y: size.height))
      cgContext.addLine(to: .init(x: size.width + 24, y: size.height))
      cgContext.addLine(to: .init(x: isFlatRight ? size.width + 24 : size.width + 12, y: 0))
      cgContext.closePath()

      switch fill {
      case let .gradient(from, to):
        cgContext.clip()

        let gradient = CGGradient(
          colorsSpace: .init(name: CGColorSpace.genericRGBLinear),
          colors: [from.cgColor, to.cgColor] as CFArray,
          locations: [0, 1]
        )!
        cgContext.drawLinearGradient(
          gradient,
          start: .init(),
          end: .init(x: 0, y: size.height),
          options: []
        )

      case let .color(color):
        cgContext.setFillColor(color.cgColor)
        cgContext.fillPath()
      }

      return true
    }
  }
}
