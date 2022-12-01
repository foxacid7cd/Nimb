//
//  Unpacker.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 01.12.2022.
//

import AsyncAlgorithms
import Backbone
import Foundation

public protocol UnpackerProtocol {
  func run() async throws
  func unpackedBatches() async -> AnyAsyncSequence<[Value]>
}

public protocol DataSource {
  func dataBatches() async -> AnyAsyncThrowingSequence<Data>
}

public actor Unpacker: UnpackerProtocol {
  public init(dataSource: DataSource) {
    self.dataSource = dataSource

    msgpack_unpacker_init(&self.mpac, Int(MSGPACK_UNPACKER_INIT_BUFFER_SIZE))
    msgpack_unpacked_init(&self.unpacked)
  }

  deinit {
    msgpack_unpacked_destroy(&unpacked)
    msgpack_unpacker_destroy(&mpac)
  }

  public func run() async throws {
    for try await data in await self.dataSource.dataBatches() {
      guard !Task.isCancelled else {
        return
      }

      await self.unpackedBatchesChannel.send(
        try self.unpack(data: data)
      )
    }
  }

  public func unpackedBatches() -> AnyAsyncSequence<[Value]> {
    self.unpackedBatchesChannel.eraseToAnyAsyncSequence()
  }

  private let dataSource: DataSource
  private var mpac = msgpack_unpacker()
  private var unpacked = msgpack_unpacked()
  private let unpackedBatchesChannel = AsyncChannel<[Value]>()

  private func unpack(data: Data) throws -> [Value] {
    if msgpack_unpacker_buffer_capacity(&self.mpac) < data.count {
      msgpack_unpacker_reserve_buffer(&self.mpac, data.count)
    }

    data.withUnsafeBytes { pointer in
      msgpack_unpacker_buffer(&self.mpac)!
        .initialize(
          from: pointer.baseAddress!
            .assumingMemoryBound(to: CChar.self),
          count: pointer.count
        )
    }
    msgpack_unpacker_buffer_consumed(&self.mpac, data.count)

    var accumulator = [Value]()

    var result = msgpack_unpacker_next(&self.mpac, &self.unpacked)
    var isCancelled = false

    while !isCancelled {
      switch result {
      case MSGPACK_UNPACK_SUCCESS:
        let value = try self.value(from: self.unpacked.data)
        accumulator.append(value)

      case MSGPACK_UNPACK_CONTINUE:
        isCancelled = true

      case MSGPACK_UNPACK_PARSE_ERROR:
        throw MessageUnpackError.parseError

      default:
        throw MessageUnpackError.unexpectedResult
      }

      result = msgpack_unpacker_next(&self.mpac, &self.unpacked)
    }

    return accumulator
  }

  private func value(from object: msgpack_object) throws -> Value {
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
      var values = [Value]()

      for i in 0 ..< Int(object.via.array.size) {
        let element = object.via.array.ptr.advanced(by: i).pointee
        values.append(try self.value(from: element))
      }

      return values

    case MSGPACK_OBJECT_MAP:
      var keyValues = [(key: Value, value: Value)]()

      for i in 0 ..< Int(object.via.map.size) {
        let element = object.via.map.ptr.advanced(by: i).pointee
        keyValues.append((
          try self.value(from: element.key),
          try self.value(from: element.val)
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
