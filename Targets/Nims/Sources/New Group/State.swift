//
//  State.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 19.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import API
import AppKit
import CoreGraphics
import Library
import PersistentCollections

struct State: Hashable {
  enum Font: Hashable {
    case monospacedSystem(size: Double)
    case custom(name: String, size: Double)
  }

  struct Window: Hashable {
    var grid: CellGrid
    var origin: GridPoint
    var anchor: Anchor
    var isHidden: Bool
    var zIndex: Int

    var ref: ExtendedTypes.Window?

    var frame: GridRectangle {
      let origin: GridPoint
      switch self.anchor {
      case .bottomLeft:
        origin = .init(
          row: self.origin.row - self.grid.size.rowsCount,
          column: self.origin.column
        )

      case .bottomRight:
        origin = .init(
          row: self.origin.row - self.grid.size.rowsCount,
          column: self.origin.column - self.grid.size.columnsCount
        )

      case .topLeft:
        origin = self.origin

      case .topRight:
        origin = .init(
          row: self.origin.row,
          column: self.origin.column - self.grid.size.columnsCount
        )
      }

      return .init(origin: origin, size: self.grid.size)
    }
  }

  struct Cursor: Hashable {
    var gridID: Int
    var position: GridPoint
  }

  struct Color: Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    mutating func multiplyAlpha(by value: Double) {
      self.alpha *= value
    }
  }

  struct Highlight: Hashable {
    var foregroundColor: Color?
    var backgroundColor: Color?
    var specialColor: Color?
    var reverse = false
    var blend = 0
    var italic = false
    var bold = false
  }

  var windows = PersistentDictionary<Int, Window>()
  var cursor: Cursor?
  var font = Font.custom(name: "MesloLGS NF", size: 13)
  var outerGridSize = GridSize(rowsCount: 40, columnsCount: 150)
  var highlights = PersistentDictionary<Int, Highlight>()
  var defaultHighlight = Highlight()

  mutating func withMutableWindowIfExists(gridID: Int, _ body: (inout Window) -> Void) {
    guard var window = self.windows[gridID] else {
      return
    }
    body(&window)
    self.windows[gridID] = window
  }

  mutating func withMutableHighlight(id: Int, _ body: (inout Highlight) -> Void) {
    var highlight = self.highlights[id] ?? .init()
    body(&highlight)
    self.highlights[id] = highlight
  }

  func foregroundColor(for index: GridPoint, gridID: Int) -> Color? {
    if let hlID = self.windows[gridID]?.grid[index]?.hlID, let highlight = self.highlights[hlID] {
      return highlight.reverse ? highlight.backgroundColor : highlight.foregroundColor

    } else {
      return self.defaultHighlight.reverse ? self.defaultHighlight.backgroundColor : self.defaultHighlight.foregroundColor
    }
  }

  func backgroundColor(for index: GridPoint, gridID: Int) -> Color? {
    if let hlID = self.windows[gridID]?.grid[index]?.hlID, let highlight = self.highlights[hlID] {
      return highlight.reverse ? highlight.foregroundColor : highlight.backgroundColor

    } else {
      return self.defaultHighlight.reverse ? self.defaultHighlight.foregroundColor : self.defaultHighlight.backgroundColor
    }
  }

  func cursorPosition(gridID: Int) -> GridPoint? {
    guard let cursor, cursor.gridID == gridID else {
      return nil
    }

    return cursor.position
  }
}

extension State.Color {
  init(hex: UInt, alpha: Double) {
    self.init(
      red: Double((hex & 0xFF0000) >> 16) / 255.0,
      green: Double((hex & 0xFF00) >> 8) / 255.0,
      blue: Double(hex & 0xFF) / 255.0,
      alpha: alpha
    )
  }

  var cgColor: CGColor {
    .init(red: red, green: green, blue: blue, alpha: alpha)
  }
}