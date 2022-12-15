// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import Cocoa
import IdentifiedCollections
import Library
import MessagePack
import Neovim
import Overture
import SwiftUI

@MainActor
class Store {
  init() {
    let appearance = Appearance()
    self.appearance = appearance

    let actions: AsyncStream<Action>
    (sendAction, actions) = AsyncChannel.pipe()

    let initialState = State(
      cellSize: appearance.cellSize,
      defaultBackgroundColor: appearance.defaultBackgroundColor
    )
    let initialStateAccumulator: (state: State, effects: [StateEffect]) = (
      state: initialState,
      effects: .init()
    )

    let states = actions
      .reductions(into: initialStateAccumulator) { accum, action in
        accum.effects.removeAll(keepingCapacity: true)

        switch action {
        case .initial:
          accum.effects.append(.initial)

        case let .gridResize(event):
          let size = Size(
            width: event.width,
            height: event.height
          )

          update(&accum.state.grids[id: event.grid]) { grid in
            if grid == nil {
              grid = .init(id: event.grid)
            }

            grid!.size = size

            for y in 0 ..< size.height {
              if y >= grid!.rows.count {
                grid!.rows.append(
                  .init(appearance: appearance)
                )
              }

              let row = grid!.rows[y]
              Task { @MainActor in
                row.set(width: size.width)
              }
            }

            grid!.updateFrame()
          }

          if event.grid == 1, let grid = accum.state.grids[id: event.grid] {
            accum.state.cachedOuterGridSize = grid.size
            accum.effects.append(.outerGridSizeChanged)
          }

          accum.state.gridsChangedInTransaction = true

        case let .gridLine(event):
          let grid = accum.state.grids[id: event.grid]!

          let row = grid.rows[event.row]
          Task { @MainActor in
            _ = row.update(startIndex: event.colStart, data: event.data)
          }

          accum.state.gridsChangedInTransaction = true

        case let .gridScroll(event):
          let grid = accum.state.grids[id: event.grid]!

          let frame = Rectangle(
            origin: .init(
              x: event.left,
              y: event.top
            ),
            size: .init(
              width: event.right - event.left,
              height: event.bot - event.top
            )
          )
          let delta = Point(x: event.cols, y: event.rows)
          Task { @MainActor in
            grid.offset(frame: frame, by: delta)
          }

          accum.state.gridsChangedInTransaction = true

        case let .gridCursorGoto(event):
          accum.state.cursor = (
            gridID: event.grid,
            position: Point(
              x: event.col,
              y: event.row
            )
          )
          accum.effects.append(.cursorChanged)

        case let .gridClear(event):
          let grid = accum.state.grids[id: event.grid]!

          Task { @MainActor in
            for row in grid.rows {
              row.clear()
            }
          }

          accum.state.gridsChangedInTransaction = true

        case let .gridDestroy(event):
          _ = accum.state.grids.remove(id: event.grid)!

          accum.state.gridsChangedInTransaction = true

        case let .winPos(event):
          accum.state.grids.move(
            fromOffsets: [accum.state.grids.index(id: event.grid)!],
            toOffset: accum.state.grids.count
          )

          let frame = Rectangle(
            origin: .init(x: event.startcol, y: event.startrow),
            size: .init(width: event.width, height: event.height)
          )

          update(&accum.state.grids[id: event.grid]) { grid in
            grid!.win = .pos(frame: frame)
            grid!.updateFrame()
          }

          accum.state.gridsChangedInTransaction = true

        case let .winClose(event):
          update(&accum.state.grids[id: event.grid]) { grid in
            grid!.win = nil
            grid!.updateFrame()
          }

          accum.state.gridsChangedInTransaction = true

        case let .defaultBackgroudColor(color):
          accum.state.defaultBackgroundColor = color
          accum.effects.append(.defaultBackgroundColorChanged)

        case .flush:
          if accum.state.gridsChangedInTransaction {
            accum.state.gridsChangedInTransaction = false

            accum.effects.append(.gridsChanged)
          }
        }
      }
      .filter { !$0.effects.isEmpty }

    let initialViewModelAccumulator: (viewModel: ViewModel, effects: [ViewModelEffect])? = nil

    viewModels = states
      .reductions(into: initialViewModelAccumulator) { accum, value in
        let (state, stateEffects) = value

        if accum == nil {
          let initialViewModel = ViewModel(
            outerSize: state.cachedOuterGridSize * state.cellSize,
            grids: .init(),
            rowHeight: state.cellSize.height,
            defaultBackgroundColor: state.defaultBackgroundColor
          )
          accum = (
            viewModel: initialViewModel,
            effects: .init()
          )
        }

        accum!.effects.removeAll(keepingCapacity: true)

        for stateEffect in stateEffects {
          switch stateEffect {
          case .initial:
            accum!.effects.append(.initial)

          case .outerGridSizeChanged:
            accum!.viewModel.outerSize = state.cachedOuterGridSize * state.cellSize
            accum!.effects.append(.outerSizeChanged)

          case .gridsChanged:
            accum!.viewModel.grids = state.grids
              .map { grid in
                .init(
                  id: grid.id,
                  frame: grid.frame * state.cellSize,
                  rows: grid.rows
                )
              }
            accum!.effects.append(.canvasChanged)

          case .defaultBackgroundColorChanged:
            accum!.viewModel.defaultBackgroundColor = state.defaultBackgroundColor
            accum!.effects.append(.canvasChanged)

          case .cursorChanged:
            if let cursor = state.cursor {
              let rectangle = Rectangle(
                origin: cursor.position,
                size: .init(width: 1, height: 1)
              )
              accum!.viewModel.cursor = (
                gridID: cursor.gridID,
                rect: rectangle * state.cellSize
              )

            } else {
              accum!.viewModel.cursor = nil
            }

            accum!.effects.append(.canvasChanged)
          }
        }
      }
      .map { $0! }
      .filter { !$0.effects.isEmpty }
      .erasedToAsyncStream

    Task {
      await sendAction(.initial)
    }
  }

  let viewModels: AsyncStream<(viewModel: ViewModel, effects: [ViewModelEffect])>

  func apply(_ uiEventBatch: UIEventBatch) async throws {
    switch uiEventBatch {
    case let .defaultColorsSet(events):
      for event in events {
        appearance.setDefaultColors(
          foregroundRGB: event.rgbFg,
          backgroundRGB: event.rgbBg,
          specialRGB: event.rgbSp
        )
        await sendAction(
          .defaultBackgroudColor(
            appearance.defaultBackgroundColor
          )
        )
      }

    case let .hlAttrDefine(events):
      for event in events {
        appearance.apply(
          nvimAttr: event.rgbAttrs,
          forHighlightWithID: event.id
        )
      }

    case let .gridResize(events):
      for event in events {
        await sendAction(.gridResize(event))
      }

    case let .gridLine(events):
      for event in events {
        await sendAction(.gridLine(event))
      }

    case let .gridScroll(events):
      for event in events {
        await sendAction(.gridScroll(event))
      }

    case let .gridCursorGoto(events):
      for event in events {
        await sendAction(.gridCursorGoto(event))
      }

    case let .gridClear(events):
      for event in events {
        await sendAction(.gridClear(event))
      }

    case let .gridDestroy(events):
      for event in events {
        await sendAction(.gridDestroy(event))
      }

    case let .winPos(events):
      for event in events {
        await sendAction(.winPos(event))
      }

    case let .winClose(events):
      for event in events {
        await sendAction(.winClose(event))
      }

    case let .flush(events):
      for _ in events {
        await sendAction(.flush)
      }

    default:
      break
    }
  }

  private enum Action {
    case initial
    case gridResize(UIEvents.GridResize)
    case gridLine(UIEvents.GridLine)
    case gridScroll(UIEvents.GridScroll)
    case gridCursorGoto(UIEvents.GridCursorGoto)
    case gridClear(UIEvents.GridClear)
    case gridDestroy(UIEvents.GridDestroy)
    case winPos(UIEvents.WinPos)
    case winClose(UIEvents.WinClose)
    case defaultBackgroudColor(Color)
    case flush
  }

  private let appearance: Appearance
  private let sendAction: @Sendable (Action)
    async -> Void
}
