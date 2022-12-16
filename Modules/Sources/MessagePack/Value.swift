// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation
import msgpack

public enum Value: Hashable, ExpressibleByStringLiteral, ExpressibleByBooleanLiteral, ExpressibleByNilLiteral {
  case integer(Int)
  case float(Double)
  case boolean(Bool)
  case string(String)
  case array([Value])
  case dictionary([Value: Value])
  case binary(Data)
  case ext(type: Int8, data: Data)
  case `nil`

  public init(stringLiteral: String) {
    self = .string(stringLiteral)
  }

  public init(booleanLiteral value: Bool) {
    self = .boolean(value)
  }

  public init(nilLiteral: ()) {
    self = .nil
  }

  init(_ object: msgpack_object) {
    switch object.type {
    case MSGPACK_OBJECT_POSITIVE_INTEGER:
      self = .integer(Int(object.via.u64))

    case MSGPACK_OBJECT_NEGATIVE_INTEGER:
      self = .integer(Int(object.via.i64))

    case MSGPACK_OBJECT_FLOAT, MSGPACK_OBJECT_FLOAT32:
      self = .float(object.via.f64)

    case MSGPACK_OBJECT_BOOLEAN:
      self = .boolean(object.via.boolean)

    case MSGPACK_OBJECT_STR:
      let str = object.via.str
      let size = Int(str.size)

      let string = String(
        unsafeUninitializedCapacity: size,
        initializingUTF8With: { buffer in
          let pointer = buffer.baseAddress!

          memcpy(pointer, str.ptr, size)
          return size
        }
      )
      self = .string(string)

    case MSGPACK_OBJECT_ARRAY:
      let cArray = object.via.array

      let count = Int(cArray.size)
      var accumulator = [Value]()

      for index in 0 ..< count {
        accumulator.append(
          Value(
            cArray.ptr
              .advanced(by: index)
              .pointee
          )
        )
      }

      self = .array(accumulator)

    case MSGPACK_OBJECT_MAP:
      let map = object.via.map

      let count = Int(map.size)
      var dictionary = [Value: Value](minimumCapacity: count)

      for index in 0 ..< count {
        let kv = map.ptr
          .advanced(by: index)
          .pointee

        let key = Value(kv.key)
        let value = Value(kv.val)
        dictionary[key] = value
      }

      self = .dictionary(dictionary)

    case MSGPACK_OBJECT_BIN:
      let bin = object.via.bin

      let data = Data(
        bytes: UnsafeRawPointer(bin.ptr),
        count: Int(bin.size)
      )
      self = .binary(data)

    case MSGPACK_OBJECT_EXT:
      let ext = object.via.ext

      self = .ext(
        type: ext.type,
        data: .init(
          bytes: UnsafeRawPointer(ext.ptr),
          count: Int(ext.size)
        )
      )

    case MSGPACK_OBJECT_NIL:
      self = .nil

    default:
      preconditionFailure("Not implemented behavior for type \(object.type)")
    }
  }
}
