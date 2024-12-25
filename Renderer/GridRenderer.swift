// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import IOSurface

final class GridRenderer {
  private let ioSurface: IOSurface
  private let scale: CGFloat
  private let gridID: Int
  private let cgContext: CGContext
  private var font: NSFont
  private var cellSize: CGSize

  init(
    ioSurface: IOSurface,
    scale: CGFloat,
    gridID: Int,
    font: NSFont,
    cellSize: CGSize
  ) {
    self.ioSurface = ioSurface
    self.scale = scale
    self.gridID = gridID
    self.font = font
    self.cellSize = cellSize

    cgContext = CGContext(
      data: ioSurface.baseAddress,
      width: ioSurface.width,
      height: ioSurface.height,
      bitsPerComponent: 8,
      bytesPerRow: ioSurface.bytesPerRow,
      space: CGColorSpace(name: CGColorSpace.sRGB)!,
      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        .union(.byteOrder32Little)
        .rawValue
    )!
  }

  func setFont(_ font: NSFont, cellSize: CGSize) {
    self.font = font
    self.cellSize = cellSize
  }

  func draw(gridDrawRequest: GridDrawRequest) {
    ioSurface.lock(seed: nil)

    cgContext.setFillColor(NSColor.white.cgColor)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: CGColor(red: 1, green: 1, blue: 1, alpha: 1),
    ]
    for part in gridDrawRequest.parts {
      let attributedString = NSAttributedString(
        string: part.text,
        attributes: attributes
      )
      let line = CTLineCreateWithAttributedString(attributedString)
      var position = IntegerPoint(
        column: part.columnsRange.lowerBound,
        row: part.row
      ) * cellSize
      position.y = CGFloat(cgContext.height) - position.y - cellSize.height
      cgContext.textPosition = position

      CTLineDraw(line, cgContext)
    }

    cgContext.flush()

    ioSurface.unlock(seed: nil)
  }

//  func render(state: State, updates: State.Updates) {
//    if updates.isAppearanceChanged {
//      surface.lock(options: [], seed: nil)
//      defer { surface.unlock(options: [], seed: nil) }
//
//      let cgContext = CGContext(
//        data: surface.baseAddress,
//        width: surface.width,
//        height: surface.height,
//        bitsPerComponent: 8,
//        bytesPerRow: surface.bytesPerRow,
//        space: CGColorSpaceCreateDeviceRGB(),
//        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
//      )!
//      cgContext.scaleBy(x: scale, y: scale)
//      NSGraphicsContext.current = .init(
//        cgContext: cgContext,
//        flipped: false
//      )
//
//      let graphicsContext = NSGraphicsContext.current!
//      defer { graphicsContext.flushGraphics() }
//
//      NSColor.red.withAlphaComponent(0.8).setFill()
//      NSRect(
//        origin: .zero,
//        size: .init(width: 200, height: 200)
//      ).fill()
//    }
//  }
}
