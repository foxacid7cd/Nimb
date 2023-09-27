// SPDX-License-Identifier: MIT

import Library
import Tagged

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
}
