//
//  GridsView.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import API
import AppKit
import CasePaths
import Combine
import Library
import PersistentCollections
import RxCocoa
import RxSwift

class GridsView: NSView {
  @MainActor
  init(frame: CGRect, state: State) {
    self.state = state
    super.init(frame: frame)

    for (id, window) in state.windows {
      self.insertGridView(id: id, window: window)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @MainActor
  func handle(state: State, events: [Event]) async {
    let previousTask = self.handleTask

    self.handleTask = Task {
      await previousTask?.value

      self.state = state
      for gridView in self.gridViews.values {
        gridView.state = state
      }

      for event in events {
        guard !Task.isCancelled else {
          break
        }

        switch event {
        case let .grid(id, model):
          switch model {
          case .windowFrameChanged:
            guard let window = state.windows[id] else { break }

            if let gridView = self.gridViews[id] {
              gridView.frame = self.rect(for: window.frame)
              gridView.isHidden = window.isHidden
              gridView.setNeedsDrawing()

            } else {
              self.insertGridView(id: id, window: window)
            }

          case .windowHid:
            self.gridViews[id]?.isHidden = true

          case .windowClosed:
            let gridView = self.gridViews.removeValue(forKey: id)
            gridView?.removeFromSuperview()

          case .windowGridCleared:
            self.gridViews[id]?.setNeedsDrawing()

          case let .windowGridRowChanged(origin, columnsCount):
            self.gridViews[id]?.setNeedsDrawing(
              .init(origin: origin, size: .init(rowsCount: 1, columnsCount: columnsCount))
            )

          case let .windowGridRectangleChanged(rectangle):
            self.gridViews[id]?.setNeedsDrawing(rectangle)

          case let .windowGridRowsMoved(originRow, rowsCount, delta):
            guard let window = state.windows[id] else {
              break
            }

            let toRectangle = GridRectangle(
              origin: .init(row: originRow - delta, column: 0),
              size: .init(rowsCount: rowsCount, columnsCount: window.grid.size.columnsCount)
            )
            .intersection(.init(origin: .init(), size: window.grid.size))

            if let toRectangle {
              self.gridViews[id]?.setNeedsDrawing(toRectangle)
            }
          }

        case let .cursor(previousCusor):
          if let previousCusor {
            handle(cursor: previousCusor)
          }

          if let cursor = self.state.cursor {
            handle(cursor: cursor)
          }

          @MainActor
          func handle(cursor: State.Cursor) {
            self.gridViews[cursor.gridID]?.setNeedsDrawing(
              .init(origin: cursor.position, size: .init(rowsCount: 1, columnsCount: 1))
            )
          }

        case .appearanceChanged:
          for gridView in self.gridViews.values {
            gridView.setNeedsDrawing()
          }

        case .flushRequested:
          for gridView in self.gridViews.values {
            gridView.flushIfNeeded()
          }
        }
      }
    }
  }

  @MainActor
  private var handleTask: Task<Void, Never>?
  @MainActor
  private var gridViews = PersistentDictionary<Int, GridView>()
  @MainActor
  private var state: State

  @MainActor
  private func insertGridView(id: Int, window: State.Window) {
    let gridView = GridView(
      frame: self.rect(for: window.frame),
      state: self.state,
      gridID: id
    )
    self.gridViews[id] = gridView
    gridView.isHidden = window.isHidden

    let relativeSubview = self.subviews
      .map { self.state.windows[($0 as! GridView).gridID]!.zIndex }
      .firstIndex(where: { $0 > window.zIndex })
      .map { self.subviews[$0] }

    if let relativeSubview {
      self.addSubview(gridView, positioned: .below, relativeTo: relativeSubview)

    } else {
      self.addSubview(gridView)
    }
  }

  @MainActor
  private func rect(for rectangle: GridRectangle) -> CGRect {
    return CellsGeometry.upsideDownRect(
      from: CellsGeometry.cellsRect(
        for: rectangle,
        cellSize: self.state.fontDerivatives.cellSize
      ),
      parentViewHeight: self.bounds.height
    )
  }
}
