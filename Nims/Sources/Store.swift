// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import Cocoa
import IdentifiedCollections
import Library
import MessagePack
import Neovim

actor Store {
  init() {
    (sendUpdate, updates) = AsyncChannel.pipe(bufferingPolicy: .unbounded)
  }

  enum Update {
    case cellSize
    case newGrid(Grid)
  }

  let updates: AsyncStream<Update>

  var cellSize: CGSize {
    get async {
      await appearance.cellSize
    }
  }

  func apply(_ uiEventBatch: UIEventBatch) async throws {
    switch uiEventBatch {
    case let .defaultColorsSet(events):
      for try await event in events {
        await appearance.setDefaultColors(
          foregroundRGB: event.rgbFg,
          backgroundRGB: event.rgbBg,
          specialRGB: event.rgbSp
        )
      }

    case let .hlAttrDefine(events):
      for try await event in events {
        await appearance.apply(
          nvimAttr: event.rgbAttrs,
          forHighlightWithID: event.id
        )
      }

    case let .gridResize(events):
      for try await event in events {
        if grids[id: event.grid] != nil {
          assertionFailure()
        }

        let newGrid = Grid(
          appearance: appearance,
          id: event.grid,
          size: .init(
            width: event.width,
            height: event.height
          )
        )
        grids.append(newGrid)

        await sendUpdate(.newGrid(newGrid))
      }

    case let .gridLine(events):
      for try await event in events {
        guard let grid = grids[id: event.grid] else {
          assertionFailure("Missing required grid with id (\(event.grid)).")
          continue
        }

        await grid.update(
          origin: .init(
            x: event.colStart,
            y: event.row
          ),
          data: event.data
        )
      }

    default:
      break
    }
  }

  private let appearance = Appearance()
  private var grids = IdentifiedArrayOf<Grid>()
  private let sendUpdate: @Sendable (Update) async -> Void
}

// actor Store {
//  init(rpcService: RPCProtocol) {
//    self.rpcService = rpcService
//  }
//
//  func run() async throws {
//    try await withThrowingTaskGroup(of: Void.self) { group in
//      group.addTask {
////        for await notification in await self.rpcService.notifications() {
////          print(notification)
////        }
//      }
//
//      group.addTask {
////        try await self.rpcService.run()
//      }
//
//      group.addTask {
////        let response = await self.rpcService.call(
////          method: "nvim_ui_attach",
////          parameters: [80, 24, [("rgb", true)]]
////        )
////
////        if !response.isSuccess {
////          throw StoreError.nvimUIAttachFailed(payload: response.payload)
////        }
//      }
//
//      try await group.waitForAll()
//    }
//  }
//
//  func gridResize(id: Grid.ID, size: Size) {
//    let grid = Grid(appearance: appearance, id: id, size: size)
//    grids[id: id] = grid
//  }
//
//  func gridLine(parametersBatches _: TreeDictionary<
//    Grid.ID,
//    [(origin: Point, data: [MessageValue])]
//  >) async {
////    await withTaskGroup(of: Void.self) { taskGroup in
////      for (id, parametersBatch) in parametersBatches {
////        guard let grid = self.grid(id: id) else {
////          continue
////        }
////
////        taskGroup.addTask {
////          await grid.update(parametersBatch: parametersBatch)
////        }
////      }
////
////      for await () in taskGroup {}
////    }
//  }
//
//  private let rpcService: RPCProtocol
//  private let appearance = Appearance()
//  private var grids = IdentifiedArrayOf<Grid>()
//
//  private func grid(id: Grid.ID) -> Grid? {
//    grids[id: id]
//  }
// }
//
// enum StoreError: Error {
//  case nvimUIAttachFailed
// }
