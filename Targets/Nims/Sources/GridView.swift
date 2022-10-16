//
//  GridView.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Library

class GridView: NSView {
  init(id: Int, store: Store) {
    self.id = id
    self.store = store

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .natural
    paragraphStyle.lineBreakMode = .byWordWrapping

    let font = NSFont.monospacedSystemFont(ofSize: 24, weight: .regular)

    let textAttributes = [
      NSAttributedString.Key.paragraphStyle: paragraphStyle,
      NSAttributedString.Key.font: font,
      NSAttributedString.Key.foregroundColor: NSColor.white
    ]
    let attributedString = CFAttributedStringCreate(nil, "Hello World!" as CFString, textAttributes as CFDictionary)!

    let ctFramesetter = CTFramesetterCreateWithAttributedString(attributedString)
    self.ctFramesetter = ctFramesetter

    let ctFrame = CTFramesetterCreateFrame(
      ctFramesetter,
      .init(location: 0, length: "Hello World!".count),
      .init(rect: .init(x: 50, y: -50, width: 300, height: 300), transform: nil),
      nil
    )
    self.ctFrame = ctFrame

    super.init(frame: .init())

    setNeedsDisplay(bounds)

    Task {
      for await array in store.notifications {
        for notification in array {
          switch notification {
          case let .gridUpdated(id, updates):
            guard id == self.id else {
              continue
            }

            switch updates {
            case let .line(row, columnStart, cellsCount):
              let updatedRect = self.cellsRect(
                first: (row, columnStart),
                second: (row, columnStart + cellsCount - 1)
              )
              setNeedsDisplay(updatedRect)
            }

          default:
            continue
          }
        }
      }
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func draw(_: NSRect) {
    guard let context = NSGraphicsContext.current else {
      "missing current graphics context".fail().failAssertion()
      return
    }
    context.saveGraphicsState()
    defer { context.restoreGraphicsState() }

    var rects: UnsafePointer<NSRect>!
    var count = 0
    getRectsBeingDrawn(&rects, count: &count)

    let grid = self.store.state.grids[self.id]!

    for index in 0 ..< count {
      let rect = rects.advanced(by: index).pointee

      let gridIntersection = self.gridIntersection(with: rect)
      for rowOffset in 0 ..< gridIntersection.width {
        for columnOffset in 0 ..< gridIntersection.height {
          let row = gridIntersection.row + rowOffset
          let column = gridIntersection.column + columnOffset
          let cell = grid[.init(row: row, column: column)]

          context.cgContext.setFillColor(
            red: CGFloat((0 ..< 10).randomElement() ?? 0) / 10.0,
            green: 0.5,
            blue: 0.5,
            alpha: 1
          )
          context.cgContext.fill(self.cellRect(row: row, column: column))
        }
      }
    }

    CTFrameDraw(self.ctFrame, context.cgContext)
  }

  private let id: Int
  private let store: Store
  private var ctFramesetter: CTFramesetter
  private var ctFrame: CTFrame

  private func gridIntersection(with rect: CGRect) -> (row: Int, column: Int, width: Int, height: Int) {
    let offset = CGPoint()
    let cellSize = self.store.state.cellSize

    let row = max(0, Int(floor((self.bounds.height - offset.y - (rect.origin.y + rect.size.height)) / cellSize.height)))
    let width = min(
      self.store.state.grids[self.id]!.rowsCount,
      Int(ceil((self.bounds.height - offset.y - rect.origin.y) / cellSize.height))
    ) - row

    let column = max(0, Int(floor((rect.origin.x - offset.x) / cellSize.width)))
    let height = min(
      self.store.state.grids[self.id]!.columnsCount,
      Int(ceil((rect.origin.x - offset.x + rect.size.width) / cellSize.width))
    ) - column

    return (row, column, width, height)
  }

  private func cellsRect(first: (row: Int, column: Int), second: (row: Int, column: Int)) -> CGRect {
    let firstRect = self.cellRect(row: first.row, column: first.column)
    let secondRect = self.cellRect(row: second.row, column: second.column)
    return firstRect.union(secondRect)
  }

  private func cellRect(row: Int, column: Int) -> CGRect {
    .init(
      origin: self.cellOrigin(row: row, column: column),
      size: self.store.state.cellSize
    )
  }

  private func cellOrigin(row: Int, column: Int) -> CGPoint {
    .init(
      x: Double(column) * self.store.state.cellSize.width,
      y: Double(row) * self.store.state.cellSize.height
    )
  }
}
