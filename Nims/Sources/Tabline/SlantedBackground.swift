// SPDX-License-Identifier: MIT

import AppKit

enum SlantedBackgroundImageType {
  case background(isFlatLeft: Bool, isFlatRight: Bool)
  case mask
}

extension NSImage {
  static func makeSlantedBackground(type: SlantedBackgroundImageType, size: CGSize, color: NSColor) -> NSImage {
    switch type {
    case let .background(isFlatLeft, isFlatRight):
      .init(size: .init(width: size.width + 24, height: size.height), flipped: false) { _ in
        let graphicsContext = NSGraphicsContext.current!
        let cgContext = graphicsContext.cgContext

        cgContext.beginPath()
        cgContext.move(to: .init())
        cgContext.addLine(to: .init(x: isFlatLeft ? 0 : 12, y: size.height))
        cgContext.addLine(to: .init(x: size.width + 24, y: size.height))
        cgContext.addLine(to: .init(x: isFlatRight ? size.width + 24 : size.width + 12, y: 0))
        cgContext.closePath()

        cgContext.clip()

        let gradient = CGGradient(
          colorsSpace: .init(name: CGColorSpace.genericRGBLinear),
          colors: [color.withAlphaComponent(0.7).cgColor, color.cgColor] as CFArray,
          locations: [0, 1]
        )!
        cgContext.drawLinearGradient(gradient, start: .init(), end: .init(x: 0, y: size.height), options: [])

        return true
      }

    case .mask:
      .init(size: .init(width: size.width + 24, height: size.height), flipped: false) { rect in
        let graphicsContext = NSGraphicsContext.current!
        let cgContext = graphicsContext.cgContext

        cgContext.beginPath()
        cgContext.move(to: .init())
        cgContext.addLine(to: .init(x: 12, y: size.height))
        cgContext.addLine(to: .init(x: size.width + 24, y: size.height))
        cgContext.addLine(to: .init(x: size.width + 12, y: 0))
        cgContext.closePath()

        let path = cgContext.path!
        let reversedPath = NSBezierPath(cgPath: path).reversed.cgPath

        if !cgContext.isPathEmpty {
          cgContext.clip()
          cgContext.resetClip()
          cgContext.addPath(reversedPath)
          cgContext.clip()
        }

        cgContext.setFillColor(color.cgColor)
        cgContext.fill([rect])

        return true
      }
    }
  }
}
