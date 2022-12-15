// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import Cocoa
import IdentifiedCollections
import Library
import MessagePack
import Neovim

@MainActor
class Store {
  init() {
    (sendEvent, events) = AsyncChannel.pipe()

    let appearance = Appearance()
    self.appearance = appearance

    viewModel = ViewModel(
      outerSize: .init(),
      grids: .init(),
      rowHeight: appearance.cellSize.height,
      defaultBackgroundColor: appearance.defaultBackgroundColor
    )
  }

  public enum Event {
    case viewModelChanged
  }

  public let events: AsyncStream<Event>

  private(set) var viewModel: ViewModel

  func apply(_ uiEventBatch: UIEventBatch) async throws {
    switch uiEventBatch {
    case let .defaultColorsSet(events):
      for try await event in events {
        appearance.setDefaultColors(
          foregroundRGB: event.rgbFg,
          backgroundRGB: event.rgbBg,
          specialRGB: event.rgbSp
        )

        viewModel.defaultBackgroundColor = appearance.defaultBackgroundColor
        await sendEvent(.viewModelChanged)
      }

    case let .hlAttrDefine(events):
      for try await event in events {
        appearance.apply(
          nvimAttr: event.rgbAttrs,
          forHighlightWithID: event.id
        )
      }

    case let .gridResize(events):
      for try await event in events {
        let size = Size(
          width: event.width,
          height: event.height
        )

        if let grid = grids[id: event.grid] {
          grid.set(size: size)

          viewModel.grids[id: event.grid]!.frame = grid.frame

        } else {
          let newGrid = Grid(
            id: event.grid,
            size: size,
            cellSize: appearance.cellSize
          )
          grids[id: event.grid] = newGrid

          viewModel.grids[id: event.grid] = .init(
            id: event.grid,
            frame: newGrid.frame,
            rows: (0 ..< size.height)
              .map { index in
                let row = newGrid.rows[index]

                return .init(
                  id: index,
                  attributedString: row.attributedString
                    .settingAttributes(appearance.attributeContainer())
                )
              }
          )
        }

        if event.grid == 1 {
          updateOuterSize()
        }

        await sendEvent(.viewModelChanged)
      }

    case let .gridLine(events):
      for try await event in events {
        let grid = grids[id: event.grid]!

        _ = grid.update(
          origin: .init(
            x: event.colStart,
            y: event.row
          ),
          data: event.data
        )

        let attributedString = grid.rows[event.row]
          .attributedString
          .settingAttributes(appearance.attributeContainer())

        viewModel.grids[id: event.grid]!.rows[event.row]
          .attributedString = attributedString

        await sendEvent(.viewModelChanged)
      }

    case let .gridClear(events):
      for try await event in events {
        let grid = grids[id: event.grid]!
        grid.clear()

        viewModel.grids[id: event.grid]!.rows = grid.rows
          .enumerated()
          .map { offset, row in
            .init(
              id: offset,
              attributedString: row.attributedString
                .settingAttributes(appearance.attributeContainer())
            )
          }
        await sendEvent(.viewModelChanged)
      }

    case let .gridDestroy(events):
      for try await event in events {
        _ = grids.remove(id: event.grid)!

        _ = viewModel.grids.remove(id: event.grid)!
        await sendEvent(.viewModelChanged)
      }

    case let .winPos(events):
      for try await event in events {
        grids.move(
          fromOffsets: [grids.index(id: event.grid)!],
          toOffset: grids.count
        )

        let grid = grids[id: event.grid]!
        grid.set(
          win: .init(
            frame: .init(
              origin: .init(
                x: event.startcol,
                y: event.startrow
              ),
              size: .init(
                width: event.width,
                height: event.height
              )
            )
          )
        )

        // var viewModelGrid = viewModel.grids.remove(id: event.grid)!
        // viewModelGrid.frame = grid.frame
        // viewModel.grids[id: event.grid] = viewModelGrid
        viewModel.grids[id: event.grid]!.frame = grid.frame
        viewModel.grids.move(
          fromOffsets: [viewModel.grids.index(id: event.grid)!],
          toOffset: viewModel.grids.count
        )
        await sendEvent(.viewModelChanged)
      }

    case let .winClose(events):
      for try await event in events {
        let grid = grids[id: event.grid]!
        grid.set(win: nil)

        viewModel.grids[id: event.grid]!.frame = grid.frame
        await sendEvent(.viewModelChanged)
      }

    default:
      break
    }
  }

  private let appearance: Appearance
  private let sendEvent: @Sendable (Event)
    async -> Void
  private var grids = IdentifiedArrayOf<Grid>()
  private var outerSize = CGSize()

  private func updateOuterSize() {
    guard let grid = grids[id: 1] else {
      return
    }

    let outerSize = grid.frame.size
    if outerSize != self.outerSize {
      self.outerSize = outerSize

      viewModel.outerSize = outerSize
    }
  }
}
