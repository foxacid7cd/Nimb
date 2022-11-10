//
//  GridsView.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import API
import AppKit
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

    self.wantsLayer = true

    for (id, window) in state.windows {
      self.insertGridLayer(id: id, window: window)
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
      for gridLayer in self.gridLayers.values {
        guard let previousViewState = gridLayer.viewState, let window = state.windows[previousViewState.id] else { continue }

        gridLayer.viewState = .init(id: previousViewState.id, state: state, window: window, fontDerivatives: state.fontDerivatives)
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

            if let gridLayer = self.gridLayers[id] {
              gridLayer.viewState = .init(id: id, state: state, window: window, fontDerivatives: state.fontDerivatives)
              gridLayer.frame = self.rect(for: window.frame)
              gridLayer.isHidden = window.isHidden
              gridLayer.zPosition = CGFloat(window.zIndex)

            } else {
              self.insertGridLayer(id: id, window: window)
            }

          case .windowHid:
            self.gridLayers[id]?.isHidden = true

          case .windowClosed:
            let gridLayer = self.gridLayers.removeValue(forKey: id)
            gridLayer?.removeFromSuperlayer()

          case .windowGridCleared:
            guard let window = state.windows[id], let gridLayer = self.gridLayers[id] else {
              break
            }

            gridLayer.setNeedsDrawing(.init(size: window.grid.size))

          case let .windowGridRowChanged(origin, columnsCount):
            self.gridLayers[id]?.setNeedsDrawing(
              .init(origin: origin, size: .init(rowsCount: 1, columnsCount: columnsCount))
            )

          case let .windowGridRectangleChanged(rectangle):
            self.gridLayers[id]?.setNeedsDrawing(rectangle)

          case let .windowGridRowsMoved(originRow, rowsCount, delta):
            guard let window = state.windows[id], let gridLayer = self.gridLayers[id] else {
              break
            }

            let rectangle = GridRectangle(
              origin: .init(row: originRow - delta, column: 0),
              size: .init(rowsCount: rowsCount, columnsCount: window.grid.size.columnsCount)
            )
            .intersection(.init(origin: .init(), size: window.grid.size))
            guard let rectangle else { break }

            gridLayer.setNeedsDrawing(rectangle)
//            gridView.enque(
//              drawingRequest: .copy(
//                from: .init(
//                  origin: .init(row: originRow, column: 0),
//                  size: .init(rowsCount: rowsCount, columnsCount: window.grid.size.columnsCount)
//                ),
//                originDelta: .init(row: delta, column: 0)
//              )
//            )
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
            self.gridLayers[cursor.gridID]?.setNeedsDrawing(
              .init(
                origin: cursor.position,
                size: .init(rowsCount: 1, columnsCount: 1)
              )
            )
          }

        case .appearanceChanged:
          break

        case .flushRequested:
          for gridLayer in self.gridLayers.values {
            // gridView.flush()
          }
        }
      }
    }
  }

  @MainActor
  private var handleTask: Task<Void, Never>?
  @MainActor
  private var gridLayers = PersistentDictionary<Int, GridLayer>()
  @MainActor
  private var state: State

  @MainActor
  private func insertGridLayer(id: Int, window: State.Window) {
    let gridLayer = GridLayer(layer: self.layer!)
    gridLayer.viewState = .init(id: id, state: self.state, window: window, fontDerivatives: self.state.fontDerivatives)
    gridLayer.delegate = self
    self.gridLayers[id] = gridLayer
    gridLayer.isHidden = window.isHidden
    gridLayer.zPosition = CGFloat(window.zIndex)
    self.layer?.addSublayer(gridLayer)

//    let relativeSubview = self.subviews
//      .map { self.state.windows[($0 as! GridView).gridID]!.zIndex }
//      .firstIndex(where: { $0 > window.zIndex })
//      .map { self.subviews[$0] }
//
//    if let relativeSubview {
//      self.addSubview(gridView, positioned: .below, relativeTo: relativeSubview)
//
//    } else {
//      self.addSubview(gridView)
//    }
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

extension GridsView: CALayerDelegate {
  func layerWillDraw(_ layer: CALayer) {
    let scaleFactor = self.window?.backingScaleFactor ?? 1
    layer.contentsScale = scaleFactor
    layer.contentsGravity = .center
    layer.needsDisplayOnBoundsChange = true
    layer.allowsEdgeAntialiasing = true
    layer.drawsAsynchronously = false
  }
}
