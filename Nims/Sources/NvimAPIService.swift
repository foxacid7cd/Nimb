// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import Backbone
import Foundation
import NvimAPI
import OSLog

actor NvimRPCService {
  init(rpcService: RPCServiceProtocol) {
    self.rpcService = rpcService
  }

  enum Event {
    case gridResize(id: Grid.ID, size: Size)
    case gridLine(id: Grid.ID, origin: Point, data: [Value])
  }

  func run() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
//        for await notification in await self.rpcService.notifications() {}
      }

      group.addTask {
//        try await self.rpcService.run()
      }

      try await group.waitForAll()
    }
  }

  func events() -> AsyncStream<Event> {
    fatalError()
  }

  func nvimUIAttach(size _: Size) async {
//    let parameters: [Value] = [size.width, size.height, [("rgb", true), ("ext_multigrid", true)]]
//    let response = try! await rpcService.call(method: "nvim_ui_attach", parameters: parameters)
//
//    if !response.isSuccess {
//      os_log("nvim_ui_attach failed: \(response.payload.debugDescription)")
//    }
  }

  private let rpcService: RPCServiceProtocol
//  private let eventChannel = AsyncChannel<Event>()
}
