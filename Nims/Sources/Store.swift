//
//  Store.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 01.12.2022.
//

import AsyncAlgorithms
import Backbone
import Collections
import IdentifiedCollections
import NvimAPI

actor Store {
  init(rpcService: RPCServiceProtocol) {
    self.rpcService = rpcService
  }

  func run() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
//        for await notification in await self.rpcService.notifications() {
//          print(notification)
//        }
      }

      group.addTask {
//        try await self.rpcService.run()
      }

      group.addTask {
//        let response = await self.rpcService.call(
//          method: "nvim_ui_attach",
//          parameters: [80, 24, [("rgb", true)]]
//        )
//
//        if !response.isSuccess {
//          throw StoreError.nvimUIAttachFailed(payload: response.payload)
//        }
      }

      try await group.waitForAll()
    }
  }

  func gridResize(id: Grid.ID, size: Size) {
    let grid = Grid(appearance: appearance, id: id, size: size)
    grids[id: id] = grid
  }

  func gridLine(parametersBatches: TreeDictionary<Grid.ID, [(origin: Point, data: [Value])]>) async {
    await withTaskGroup(of: Void.self) { taskGroup in
      for (id, parametersBatch) in parametersBatches {
        guard let grid = self.grid(id: id) else {
          continue
        }

        taskGroup.addTask {
          await grid.update(parametersBatch: parametersBatch)
        }
      }

      for await () in taskGroup {}
    }
  }

  private let rpcService: RPCServiceProtocol
  private let appearance = Appearance()
  private var grids = IdentifiedArrayOf<Grid>()

  private func grid(id: Grid.ID) -> Grid? {
    grids[id: id]
  }
}

enum StoreError: Error {
  case nvimUIAttachFailed(payload: Value)
}
