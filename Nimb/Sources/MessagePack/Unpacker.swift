// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import CustomDump
import Foundation

@MainActor
public class Unpacker {
  public init() {
    msgpack_unpacker_init(&mpac, Int(MSGPACK_UNPACKER_INIT_BUFFER_SIZE))
    msgpack_unpacked_init(&unpacked)
  }

  deinit {
    msgpack_unpacked_destroy(&unpacked)
    msgpack_unpacker_destroy(&mpac)
  }

  public func unpack(_ data: Data) throws -> [Value] {
    if msgpack_unpacker_buffer_capacity(&mpac) < data.count {
      msgpack_unpacker_reserve_buffer(&mpac, data.count)
    }

    data.withUnsafeBytes { pointer in
      msgpack_unpacker_buffer(&mpac)!
        .initialize(
          from: pointer.baseAddress!.assumingMemoryBound(to: CChar.self),
          count: pointer.count
        )
    }
    msgpack_unpacker_buffer_consumed(&mpac, data.count)

    var accumulator = [Value]()
    while true {
      let result = msgpack_unpacker_next(&mpac, &unpacked)

      switch result {
      case MSGPACK_UNPACK_EXTRA_BYTES,
           MSGPACK_UNPACK_SUCCESS:
        accumulator.append(.init(unpacked.data))

      case MSGPACK_UNPACK_CONTINUE:
        return accumulator

      case MSGPACK_UNPACK_PARSE_ERROR:
        throw Failure("MSGPACK_UNPACK_PARSE_ERROR")

      case MSGPACK_UNPACK_NOMEM_ERROR:
        throw Failure("MSGPACK_UNPACK_NOMEM_ERROR")

      default:
        throw Failure("Invalid msgpack unpacking result \(result)")
      }
    }
  }

  private var mpac = msgpack_unpacker()
  private var unpacked = msgpack_unpacked()
}
