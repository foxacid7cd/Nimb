// SPDX-License-Identifier: MIT

import Foundation

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
        .flatMap { $0[case: \.string] },
      shortName: raw["short_name"]
        .flatMap { $0[case: \.string] },
      mouseShape: raw["mouse_shape"]
        .flatMap { $0[case: \.integer] },
      blinkOn: raw["blinkon"]
        .flatMap { $0[case: \.integer] },
      blinkOff: raw["blinkoff"]
        .flatMap { $0[case: \.integer] },
      blinkWait: raw["blinkwait"]
        .flatMap { $0[case: \.integer] },
      cellPercentage: raw["cell_percentage"]
        .flatMap { $0[case: \.integer] },
      cursorShape: raw["cursor_shape"]
        .flatMap { $0[case: \.string] }
        .flatMap(CursorShape.init(rawValue:)),
      idLm: raw["id_lm"]
        .flatMap { $0[case: \.integer] },
      attrID: raw["attr_id"]
        .flatMap { $0[case: \.integer] },
      attrIDLm: raw["attr_id_lm"]
        .flatMap { $0[case: \.integer] }
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
          height: font.cellHeight
        )
      )

    case .horizontal:
      let size = CGSize(
        width: font.cellWidth * Double(columnsCount),
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
