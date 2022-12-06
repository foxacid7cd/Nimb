// Copyright © 2022 foxacid7cd. All rights reserved.

import CasePaths
import Foundation
import msgpack

public enum Value: Hashable, ExpressibleByStringLiteral, ExpressibleByBooleanLiteral {
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

  init(_ object: msgpack_object) {
    switch object.type {
    case MSGPACK_OBJECT_POSITIVE_INTEGER:
      self = .integer(Int(object.via.u64))

    case MSGPACK_OBJECT_NEGATIVE_INTEGER:
      self = .integer(Int(object.via.i64))

    case MSGPACK_OBJECT_FLOAT:
      self = .float(object.via.f64)

    case MSGPACK_OBJECT_BOOLEAN:
      self = .boolean(object.via.boolean)

    case MSGPACK_OBJECT_STR:
      let str = object.via.str

      let originalBuffer = UnsafeBufferPointer<UInt8>(
        start: UnsafeRawPointer(str.ptr)!
          .assumingMemoryBound(to: UInt8.self),
        count: Int(str.size)
      )

      let string = String(
        unsafeUninitializedCapacity: originalBuffer.count,
        initializingUTF8With: { $0.initialize(fromContentsOf: originalBuffer) }
      )
      self = .string(string)

    case MSGPACK_OBJECT_ARRAY:
      let cArray = object.via.array

      let count = Int(cArray.size)
      let array = [Value](unsafeUninitializedCapacity: count) { buffer, initializedCount in
        let pointer = buffer.baseAddress!

        for index in 0 ..< count {
          let value = Value(
            cArray.ptr
              .advanced(by: index)
              .pointee
          )

          pointer
            .advanced(by: index)
            .pointee = value
        }

        initializedCount = count
      }
      self = .array(array)

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

  public subscript<SubValue>(casePath: CasePath<Value, SubValue>) -> SubValue? {
    casePath.extract(from: self)
  }
}
