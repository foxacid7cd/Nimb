// SPDX-License-Identifier: MIT

import Foundation
import Library

@PublicInit
public struct Cursor: Sendable {
  public var gridID: Grid.ID
  public var position: IntegerPoint
}

@PublicInit
public struct Mode: Sendable {
  public var name: String
  public var cursorStyleIndex: Int
}

@PublicInit
public struct ModeInfo: Sendable {
  public var enabled: Bool
  public var cursorStyles: [CursorStyle]
}

public enum CursorShape: String, Sendable {
  case block
  case horizontal
  case vertical
}

@PublicInit
public struct CursorStyle: Sendable {
  public var name: String?
  public var shortName: String?
  public var mouseShape: Int?
  public var blinkOn: Int?
  public var blinkOff: Int?
  public var blinkWait: Int?
  public var cellPercentage: Int?
  public var cursorShape: CursorShape?
  public var idLm: Int?
  public var attrID: Highlight.ID?
  public var attrIDLm: Int?

  public func cellFrame(font: NimsFont) -> CGRect? {
    guard let cursorShape else {
      return nil
    }
    switch cursorShape {
    case .block:
      return .init(origin: .init(), size: font.cellSize)

    case .horizontal:
      let size = CGSize(
        width: font.cellWidth,
        height: font.cellHeight / 100.0 * Double(cellPercentage ?? 25)
      )
      return .init(
        origin: .init(x: 0, y: font.cellHeight - size.height),
        size: size
      )

    case .vertical:
      let width = font.cellWidth / 100.0 * Double(cellPercentage ?? 25)
      return .init(
        origin: .init(),
        size: .init(width: width, height: font.cellHeight)
      )
    }
  }
}
