// SPDX-License-Identifier: MIT

import Darwin
import Foundation
import IOSurface

@MainActor
public final class RemoteRenderer {
  private static let sharedMemorySize = 1024 * 1024 * 1024 * 32

  private let sharedMemory = nimb_allocate_shared_memory(sharedMemorySize)!
  private let connectionToService = NSXPCConnection(serviceName: "foxacid7cd.Renderer")
  private let proxy: RendererProtocol
  private var currentOffset = 0

  public init() async {
    connectionToService.remoteObjectInterface = NSXPCInterface(with: RendererProtocol.self)
    connectionToService.resume()

    proxy = connectionToService.remoteObjectProxy as! RendererProtocol

    await withCheckedContinuation { continuation in
      proxy.set(sharedMemoryXPC: xpc_shmem_create(sharedMemory, Self.sharedMemorySize)) {
        continuation.resume()
      }
    }
  }

  public func invalidate() {
    connectionToService.invalidate()
  }

  public func register(
    surface: IOSurface,
    scale: CGFloat,
    forGridWithID gridID: Int
  ) {
    proxy
      .register(
        surface: surface,
        scale: scale,
        forGridWithID: gridID
      ) { isSuccess in
        if !isSuccess {
          logger.error("Failed to register surface")
        }
      }
  }

  public func processNvimOutput(data: Data) {
    data.withContiguousStorageIfAvailable { buffer in
      sharedMemory
        .advanced(by: currentOffset)
        .copyMemory(
          from: buffer.baseAddress!,
          byteCount: buffer.count
        )
    }
    proxy
      .processNvimOutputData(
        count: data.count,
        offset: currentOffset
      ) { }
    currentOffset += data.count
  }
}
