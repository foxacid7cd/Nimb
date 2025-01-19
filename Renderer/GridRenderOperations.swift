// SPDX-License-Identifier: MIT

import AppKit

@objc(NimbGridRenderOperationsResult)
public class GridRenderOperationsResult: NSObject, NSCoding, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public let isIOSurfaceUpdated: Bool
  public let ioSurface: IOSurface?

  public init(isIOSurfaceUpdated: Bool, ioSurface: IOSurface?) {
    self.isIOSurfaceUpdated = isIOSurfaceUpdated
    self.ioSurface = ioSurface
  }

  public required init?(coder: NSCoder) {
    isIOSurfaceUpdated = coder.decodeBool(forKey: "isIOSurfaceUpdated")
    if isIOSurfaceUpdated {
      ioSurface = coder.decodeObject(of: IOSurface.self, forKey: "ioSurface")
    } else {
      ioSurface = nil
    }
  }

  public func encode(with coder: NSCoder) {
    coder.encode(isIOSurfaceUpdated, forKey: "isIOSurfaceUpdated")
    if isIOSurfaceUpdated {
      coder.encode(ioSurface, forKey: "ioSurface")
    }
  }
}

@objc(NimbGridRenderOperations)
public class GridRenderOperations: NSObject, NSCoding, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public let array: [GridRenderOperation]

  public required init?(coder: NSCoder) {
    guard
      let array = coder.decodeArrayOfObjects(ofClass: GridRenderOperation.self, forKey: "array")
    else {
      return nil
    }
    self.array = array
  }

  public init(array: [GridRenderOperation]) {
    self.array = array
  }

  public func encode(with coder: NSCoder) {
    coder.encode(array, forKey: "array")
  }
}

@objc(NimbGridRenderOperation)
public class GridRenderOperation: NSObject, NSCoding, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public var type: GridRenderOperationType
  public var resize: GridRenderResizeOperation?
  public var draw: [GridRenderDrawOperationPart]?
  public var scroll: GridRenderScrollOperation?

  public init(
    type: GridRenderOperationType,
    resize: GridRenderResizeOperation? = nil,
    draw: [GridRenderDrawOperationPart]? = nil,
    scroll: GridRenderScrollOperation? = nil
  ) {
    self.type = type
    self.resize = resize
    self.draw = draw
    self.scroll = scroll
  }

  public required init?(coder: NSCoder) {
    guard
      let type = GridRenderOperationType(rawValue: coder.decodeInteger(forKey: "type"))
    else {
      return nil
    }

    self.type = type
    switch type {
    case .resize:
      guard
        let resize = coder.decodeObject(
          of: GridRenderResizeOperation.self,
          forKey: "resize"
        )
      else {
        return nil
      }
      self.resize = resize
      draw = nil
      scroll = nil

    case .draw:
      guard
        let draw = coder.decodeArrayOfObjects(ofClass: GridRenderDrawOperationPart.self, forKey: "draw")
      else {
        return nil
      }
      resize = nil
      self.draw = draw
      scroll = nil

    case .scroll:
      guard
        let scroll = coder.decodeObject(
          of: GridRenderScrollOperation.self,
          forKey: "scroll"
        )
      else {
        return nil
      }
      resize = nil
      draw = nil
      self.scroll = scroll
    }
  }

  public func encode(with coder: NSCoder) {
    coder.encode(type.rawValue, forKey: "type")
    switch type {
    case .resize:
      coder.encode(resize!, forKey: "resize")
    case .draw:
      coder.encode(draw!, forKey: "draw")
    case .scroll:
      coder.encode(scroll!, forKey: "scroll")
    }
  }
}

public enum GridRenderOperationType: Int {
  case resize
  case draw
  case scroll
}

@objc(NimbGridRenderResizeOperation)
public class GridRenderResizeOperation: NSObject, NSCoding, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public let font: NSFont
  public let contentsScale: Double
  public let size: IntegerSize

  public init(font: NSFont, contentsScale: Double, size: IntegerSize) {
    self.font = font
    self.contentsScale = contentsScale
    self.size = size
  }

  public required init?(coder: NSCoder) {
    guard
      let font = coder.decodeObject(of: NSFont.self, forKey: "font")
    else {
      return nil
    }
    self.font = font
    contentsScale = coder.decodeDouble(forKey: "contentsScale")
    size = .init(
      columnsCount: coder.decodeInteger(forKey: "size.columnsCount"),
      rowsCount: coder.decodeInteger(forKey: "size.rowsCount")
    )
  }

  public func encode(with coder: NSCoder) {
    coder.encode(font, forKey: "font")
    coder.encode(contentsScale, forKey: "contentsScale")
    coder.encode(size.columnsCount, forKey: "size.columnsCount")
    coder.encode(size.rowsCount, forKey: "size.rowsCount")
  }
}

@objc(NimbGridRenderDrawOperationPart)
public class GridRenderDrawOperationPart: NSObject, NSCoding, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public let row: Int
  public let colStart: Int
  public let data: [Value]
  public let wrap: Bool

  public required init?(coder: NSCoder) {
    row = coder.decodeInteger(forKey: "row")
    colStart = coder.decodeInteger(forKey: "colStart")
    wrap = coder.decodeBool(forKey: "wrap")

    guard let rawData = coder.decodeObject(of: NSData.self, forKey: "data") as? Data else {
      return nil
    }
    let unpacker = Unpacker()
    let unpacked = rawData.withUnsafeBytes { bufferPointer in
      try? unpacker.unpack(bufferPointer)
    }
    guard case let .array(data) = unpacked?.first else {
      return nil
    }

    self.data = data
  }

  init(row: Int, colStart: Int, data: [Value], wrap: Bool) {
    self.row = row
    self.colStart = colStart
    self.data = data
    self.wrap = wrap
  }

  public func encode(with coder: NSCoder) {
    coder.encode(row, forKey: "row")
    coder.encode(colStart, forKey: "colStart")
    coder.encode(wrap, forKey: "wrap")

    let packer = Packer()
    let rawData = packer.pack(.array(data))
    coder.encode(rawData as NSData, forKey: "data")
  }
}

@objc(NimbGridRenderScrollOperation)
public class GridRenderScrollOperation: NSObject, NSCoding, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool {
    true
  }

  public let rectangle: IntegerRectangle
  public let offset: IntegerSize

  public init(rectangle: IntegerRectangle, offset: IntegerSize) {
    self.rectangle = rectangle
    self.offset = offset
  }

  public required init?(coder: NSCoder) {
    rectangle = .init(
      origin: .init(
        column: coder.decodeInteger(forKey: "rectangle.origin.column"),
        row: coder.decodeInteger(forKey: "rectangle.origin.row")
      ),
      size: .init(
        columnsCount: coder.decodeInteger(forKey: "rectangle.size.columns"),
        rowsCount: coder.decodeInteger(forKey: "rectangle.size.rows")
      )
    )
    offset = .init(
      columnsCount: coder.decodeInteger(forKey: "offset.columns"),
      rowsCount: coder.decodeInteger(forKey: "offset.rows")
    )
  }

  public func encode(with coder: NSCoder) {
    coder.encode(rectangle.origin.column, forKey: "rectangle.origin.column")
    coder.encode(rectangle.origin.row, forKey: "rectangle.origin.row")
    coder.encode(rectangle.size.columnsCount, forKey: "rectangle.size.columns")
    coder.encode(rectangle.size.rowsCount, forKey: "rectangle.size.rows")
    coder.encode(offset.columnsCount, forKey: "offset.columns")
    coder.encode(offset.rowsCount, forKey: "offset.rows")
  }
}
