// SPDX-License-Identifier: MIT

import Foundation
import NimbCore

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
  public var name: String? = nil
  public var shortName: String? = nil
  public var mouseShape: Int? = nil
  public var blinkOn: Int? = nil
  public var blinkOff: Int? = nil
  public var blinkWait: Int? = nil
  public var cellPercentage: Int? = nil
  public var cursorShape: CursorShape? = nil
  public var idLm: Int? = nil
  public var attrID: Highlight.ID? = nil
  public var attrIDLm: Int? = nil

  public var shouldDrawParentText: Bool {
    guard let cursorShape else {
      return false
    }
    switch cursorShape {
    case .block:
      return true
    case .horizontal,
         .vertical:
      if let cellPercentage {
        return cellPercentage > 25
      } else {
        return false
      }
    }
  }

  public init(raw: Value) throws {
    guard case let .dictionary(raw) = raw else {
      throw Failure("invalid raw cursor style", raw)
    }

    self.init(
      name: raw["name"]
        .flatMap(\.string),
      shortName: raw["short_name"]
        .flatMap(\.string),
      mouseShape: raw["mouse_shape"]
        .flatMap(\.integer),
      blinkOn: raw["blinkon"]
        .flatMap(\.integer),
      blinkOff: raw["blinkoff"]
        .flatMap(\.integer),
      blinkWait: raw["blinkwait"]
        .flatMap(\.integer),
      cellPercentage: raw["cell_percentage"]
        .flatMap(\.integer),
      cursorShape: raw["cursor_shape"]
        .flatMap(\.string)
        .flatMap(CursorShape.init(rawValue:)),
      idLm: raw["id_lm"]
        .flatMap(\.integer),
      attrID: raw["attr_id"]
        .flatMap(\.integer),
      attrIDLm: raw["attr_id_lm"]
        .flatMap(\.integer),
    )
  }

  public func cellFrame(columnsCount: Int, font: Font) -> CGRect? {
    guard let cursorShape else {
      return nil
    }

    switch cursorShape {
    case .block:
      return .init(
        origin: .init(),
        size: .init(
          width: font.cellWidth * Double(columnsCount),
          height: font.cellHeight,
        ),
      )

    case .horizontal:
      let size = CGSize(
        width: font.cellWidth * Double(columnsCount),
        height: font.cellHeight / 100.0 * Double(cellPercentage ?? 25),
      )
      return .init(
        origin: .init(x: 0, y: font.cellHeight - size.height),
        size: size,
      )

    case .vertical:
      let width = font.cellWidth / 100.0 * Double(cellPercentage ?? 25)
      return .init(
        origin: .init(),
        size: .init(width: width, height: font.cellHeight),
      )
    }
  }
}
