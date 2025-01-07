// SPDX-License-Identifier: MIT

import AppKit

@objc(NimbGridContext)
public class GridContext: NSObject, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public var font: NSFont
  public var contentsScale: Double
  public var size: IntegerSize
  public var ioSurface: IOSurface

  public init(
    font: NSFont,
    contentsScale: Double,
    size: IntegerSize,
    ioSurface: IOSurface
  ) {
    self.font = font
    self.contentsScale = contentsScale
    self.size = size
    self.ioSurface = ioSurface
  }

  public required init?(coder: NSCoder) {
    guard
      let font = coder.decodeObject(of: NSFont.self, forKey: "font"),
      let ioSurface = coder.decodeObject(of: IOSurface.self, forKey: "ioSurface")
    else {
      return nil
    }
    self.font = font
    self.ioSurface = ioSurface

    let columnsCount = coder.decodeInteger(forKey: "columnsCount")
    let rowsCount = coder.decodeInteger(forKey: "rowsCount")
    size = .init(columnsCount: columnsCount, rowsCount: rowsCount)

    contentsScale = coder.decodeDouble(forKey: "contentsScale")
  }

  public func encode(with coder: NSCoder) {
    coder.encode(font, forKey: "font")
    coder.encode(ioSurface, forKey: "ioSurface")
    coder.encode(size.columnsCount, forKey: "columnsCount")
    coder.encode(size.rowsCount, forKey: "rowsCount")
    coder.encode(contentsScale, forKey: "contentsScale")
  }
}
