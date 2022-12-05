// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import Foundation
import Library
import msgpack

public protocol UnpackerProtocol {
  func unpack(_ data: Data) async throws -> [MessageValue]
}

public actor Unpacker: UnpackerProtocol {
  public init() {
    msgpack_unpacker_init(&mpac, Int(MSGPACK_UNPACKER_INIT_BUFFER_SIZE))
    msgpack_unpacked_init(&unpacked)
  }

  deinit {
    msgpack_unpacked_destroy(&unpacked)
    msgpack_unpacker_destroy(&mpac)
  }

  public func unpack(_ data: Data) throws -> [MessageValue] {
    if msgpack_unpacker_buffer_capacity(&mpac) < data.count {
      msgpack_unpacker_reserve_buffer(&mpac, data.count)
    }

    data.withUnsafeBytes { pointer in
      msgpack_unpacker_buffer(&self.mpac)!
        .initialize(
          from: pointer.baseAddress!
            .assumingMemoryBound(to: CChar.self),
          count: pointer.count
        )
    }
    msgpack_unpacker_buffer_consumed(&mpac, data.count)

    var accumulator = [MessageValue]()

    var result = msgpack_unpacker_next(&mpac, &unpacked)
    var isCancelled = false

    while !isCancelled {
      switch result {
      case MSGPACK_UNPACK_SUCCESS:
        let value = try value(from: unpacked.data)
        accumulator.append(value)

      case MSGPACK_UNPACK_CONTINUE:
        isCancelled = true

      case MSGPACK_UNPACK_PARSE_ERROR:
        throw MessageUnpackError.parseError

      default:
        throw MessageUnpackError.unexpectedResult
      }

      result = msgpack_unpacker_next(&mpac, &unpacked)
    }

    return accumulator
  }

  private var mpac = msgpack_unpacker()
  private var unpacked = msgpack_unpacked()

  private func value(from object: msgpack_object) throws -> MessageValue {
    switch object.type {
    case MSGPACK_OBJECT_NIL:
      return nil

    case MSGPACK_OBJECT_BOOLEAN:
      return object.via.boolean

    case MSGPACK_OBJECT_POSITIVE_INTEGER:
      return Int(object.via.u64)

    case MSGPACK_OBJECT_NEGATIVE_INTEGER:
      return Int(object.via.i64)

    case MSGPACK_OBJECT_STR:
      let str = object.via.str
      let size = Int(str.size)

      return String(unsafeUninitializedCapacity: size, initializingUTF8With: { buffer in
        let pointer = buffer.baseAddress!

        memcpy(pointer, str.ptr, size)
        return size
      })

    case MSGPACK_OBJECT_ARRAY:
      var values = [MessageValue]()

      for i in 0 ..< Int(object.via.array.size) {
        let element = object.via.array.ptr.advanced(by: i).pointee
        values.append(try value(from: element))
      }

      return values

    case MSGPACK_OBJECT_MAP:
      var keyValues = [(key: MessageValue, value: MessageValue)]()

      for i in 0 ..< Int(object.via.map.size) {
        let element = object.via.map.ptr.advanced(by: i).pointee
        keyValues.append((
          try value(from: element.key),
          try value(from: element.val)
        ))
      }

      return keyValues

    case MSGPACK_OBJECT_FLOAT, MSGPACK_OBJECT_FLOAT32:
      return Double(object.via.f64)

    case MSGPACK_OBJECT_BIN:
      let bin = object.via.bin
      let data = Data(bytes: bin.ptr, count: Int(bin.size))
      return data

    case MSGPACK_OBJECT_EXT:
      let ext = object.via.ext
      let data = Data(bytes: ext.ptr, count: Int(ext.size))
      return (data: data, type: ext.type)

    default:
      throw MessageUnpackError.unexpectedValueType
    }
  }
}

public enum MessageUnpackError: Error {
  case parseError
  case unexpectedResult
  case unexpectedValueType
}
