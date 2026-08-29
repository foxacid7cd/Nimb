// SPDX-License-Identifier: MIT

import Foundation
import NimbCore

/// Talks to a Neovim server over a unix socket, which is what `:restart` and
/// `:connect` hand over -- an address to attach to rather than a process to
/// spawn.
public struct SocketChannel: Channel {
  public struct ConnectionFailure: Error, Sendable {
    public var path: String
    public var errnoValue: Int32
  }

  /// Installed once, for the same reason ProcessChannel installs it once:
  /// reading it again would detach the previously vended stream.
  public let dataBatches: AsyncStream<Data>

  private let handle: FileHandle

  public init(path: String) throws {
    let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
    guard descriptor >= 0 else {
      throw ConnectionFailure(path: path, errnoValue: errno)
    }

    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    let capacity = MemoryLayout.size(ofValue: address.sun_path)
    guard path.utf8.count < capacity else {
      close(descriptor)
      throw ConnectionFailure(path: path, errnoValue: ENAMETOOLONG)
    }
    _ = withUnsafeMutablePointer(to: &address.sun_path) { destination in
      path.withCString { source in
        strncpy(
          UnsafeMutableRawPointer(destination).assumingMemoryBound(to: CChar.self),
          source,
          capacity - 1,
        )
      }
    }

    let result = withUnsafePointer(to: &address) { pointer in
      pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        connect(descriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
      }
    }
    guard result == 0 else {
      let failure = ConnectionFailure(path: path, errnoValue: errno)
      close(descriptor)
      throw failure
    }

    handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
    dataBatches = handle.dataBatches
  }

  public func write(_ data: Data) throws {
    try handle.write(contentsOf: data)
  }
}
