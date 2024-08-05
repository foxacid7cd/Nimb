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
  
  public func _unpack(source: UnsafeRawPointer, bytesCount: Int) throws -> (value: Value?, bytesUsed: Int) {
    let requiredCapacity = bufferedBytesCount + bytesCount
    if msgpack_unpacker_buffer_capacity(&mpac) < requiredCapacity {
      msgpack_unpacker_reserve_buffer(&mpac, requiredCapacity)
    }
    
    UnsafeMutableRawPointer(msgpack_unpacker_buffer(&mpac))!
      .copyMemory(from: source, byteCount: bytesCount)
    
    msgpack_unpacker_buffer_consumed(&mpac, bytesCount)
    
    var p_bytes = 0
    let result = msgpack_unpacker_next_with_size(&mpac, &unpacked, &p_bytes)
    
    switch result {
    case MSGPACK_UNPACK_SUCCESS, MSGPACK_UNPACK_EXTRA_BYTES:
      bufferedBytesCount = 0
      return (value: .init(unpacked.data), bytesUsed: p_bytes)
      
    case MSGPACK_UNPACK_CONTINUE:
      bufferedBytesCount += p_bytes
      return (value: nil, bytesUsed: p_bytes)
      
    case MSGPACK_UNPACK_PARSE_ERROR:
      throw Failure("MSGPACK_UNPACK_PARSE_ERROR")
      
    case MSGPACK_UNPACK_NOMEM_ERROR:
      throw Failure("MSGPACK_UNPACK_PARSE_ERROR")
      
    default:
      throw Failure("Unexpected result from msgpack_unpacker_next_with_size")
    }
  }

  private var mpac = msgpack_unpacker()
  private var unpacked = msgpack_unpacked()
  private var bufferedBytesCount = 0
}

