//
//  File.swift
//  
//
//  Created by Yevhenii Matviienko on 28.02.2023.
//

import Tagged
import Library

public struct Cursor: Sendable {
  public init(gridID: Grid.ID, position: IntegerPoint) {
    self.gridID = gridID
    self.position = position
  }

  public var gridID: Grid.ID
  public var position: IntegerPoint
}

public struct Mode: Sendable {
  public init(name: String, cursorStyleIndex: Int) {
    self.name = name
    self.cursorStyleIndex = cursorStyleIndex
  }

  public var name: String
  public var cursorStyleIndex: Int
}

public struct ModeInfo: Sendable {
  public init(enabled: Bool, cursorStyles: [CursorStyle]) {
    self.enabled = enabled
    self.cursorStyles = cursorStyles
  }

  public var enabled: Bool
  public var cursorStyles: [CursorStyle]
}


public enum CursorShape: String, Sendable {
  case block
  case horizontal
  case vertical
}

public struct CursorStyle: Sendable {
  public init(
    name: String?,
    shortName: String?,
    mouseShape: Int?,
    blinkOn: Int?,
    blinkOff: Int?,
    blinkWait: Int?,
    cellPercentage: Int?,
    cursorShape: CursorShape?,
    idLm: Int?,
    attrID: Highlight.ID?,
    attrIDLm: Int?
  ) {
    self.name = name
    self.shortName = shortName
    self.mouseShape = mouseShape
    self.blinkOn = blinkOn
    self.blinkOff = blinkOff
    self.blinkWait = blinkWait
    self.cellPercentage = cellPercentage
    self.cursorShape = cursorShape
    self.idLm = idLm
    self.attrID = attrID
    self.attrIDLm = attrIDLm
  }

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
