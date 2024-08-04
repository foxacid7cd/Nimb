// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import Foundation

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
      msgpack_unpacker_buffer(&self.mpac)!
        .initialize(
          from: pointer.baseAddress!.assumingMemoryBound(to: CChar.self),
          count: pointer.count
        )
    }
    msgpack_unpacker_buffer_consumed(&mpac, data.count)

    var accumulator = [Value]()

    var result = msgpack_unpacker_next(&mpac, &unpacked)
    var isCancelled = false

    while !isCancelled {
      switch result {
      case MSGPACK_UNPACK_SUCCESS:
        let value = Value(unpacked.data)
        accumulator.append(value)

      case MSGPACK_UNPACK_CONTINUE: isCancelled = true

      case MSGPACK_UNPACK_PARSE_ERROR:
        throw Failure("Msgpack unpacking parse error")

      default:
        throw Failure("Invalid msgpack unpacking result \(result)")
      }

      result = msgpack_unpacker_next(&mpac, &unpacked)
    }

    return accumulator
  }

  private var mpac = msgpack_unpacker()
  private var unpacked = msgpack_unpacked()
}
