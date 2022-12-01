//
//  MessagePacker.swift
//  MessagePack
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import AsyncAlgorithms
import Backbone
import Foundation
import SwiftUI

public protocol MessagePackerProtocol {
  func pack(messageValue: MessageValue) async throws
}

public actor MessagePacker: MessagePackerProtocol {
  public init(dataDestination: MessageDataDestination) {
    self.dataDestination = dataDestination

    msgpack_sbuffer_init(&self.sbuf)
    msgpack_packer_init(&self.pk, &self.sbuf, msgpack_sbuffer_write)
  }

  deinit {
    msgpack_sbuffer_destroy(&sbuf)
  }

  public func pack(messageValue: MessageValue) async throws {
    self.pack(messageValue)

    let data = Data(bytes: sbuf.data, count: self.sbuf.size)
    msgpack_sbuffer_clear(&self.sbuf)

    try await self.dataDestination.write(data: data)
  }

  private let dataDestination: MessageDataDestination
  private var sbuf = msgpack_sbuffer()
  private var pk = msgpack_packer()

  private func pack(_ messageValue: MessageValue) {
    guard let messageValue else {
      msgpack_pack_nil(&self.pk)
      return
    }

    switch messageValue {
    case let value as Bool:
      if value {
        msgpack_pack_true(&self.pk)

      } else {
        msgpack_pack_false(&self.pk)
      }

    case let value as Int:
      msgpack_pack_int64(&self.pk, Int64(value))

    case let value as String:
      value.utf8CString
        .withUnsafeBytes { bufferPointer in
          let pointer = bufferPointer.baseAddress!

          _ = msgpack_pack_str_with_body(
            &self.pk,
            pointer,
            strlen(pointer)
          )
        }

    case let value as Double:
      msgpack_pack_float(&self.pk, Float(value))

    case let keyValues as [(key: MessageValue, value: MessageValue)]:
      msgpack_pack_map(&self.pk, keyValues.count)

      for (key, value) in keyValues {
        self.pack(key)
        self.pack(value)
      }

    case let value as [MessageValue]:
      msgpack_pack_array(&self.pk, value.count)

      for element in value {
        self.pack(element)
      }

    case let value as (data: Data, type: Int8):
      value.data
        .withUnsafeBytes { bufferPointer in
          _ = msgpack_pack_ext_with_body(
            &self.pk,
            bufferPointer.baseAddress!,
            bufferPointer.count,
            value.type
          )
        }

    case let value as Data:
      value.withUnsafeBytes { bufferPointer in
        _ = msgpack_pack_bin_with_body(
          &self.pk,
          bufferPointer.baseAddress!,
          bufferPointer.count
        )
      }

    default:
      assertionFailure("Failed packing message value with unsupported type: \(messageValue)")
      return
    }
  }
}

public protocol MessageDataDestination {
  func write(data: Data) async throws
}

public protocol MessageUnpackerProtocol {
  func messageValueBatches() async -> AnyAsyncThrowingSequence<[MessageValue]>
}

public actor MessageUnpacker: MessageUnpackerProtocol {
  public init(dataSource: MessageDataSource) {
    self.dataSource = dataSource

    msgpack_unpacker_init(&self.mpac, Int(MSGPACK_UNPACKER_INIT_BUFFER_SIZE))
    msgpack_unpacked_init(&self.unpacked)
  }

  deinit {
    self.task?.cancel()

    msgpack_unpacked_destroy(&unpacked)
    msgpack_unpacker_destroy(&mpac)
  }

  public func messageValueBatches() -> AnyAsyncThrowingSequence<[MessageValue]> {
    self.messageValueBatchChannel.eraseToAnyAsyncThrowingSequence()
  }

  public func start() async {
    guard self.task == nil else {
      return
    }

    self.task = Task {
      do {
        for try await data in dataSource.data {
          guard !Task.isCancelled else {
            return
          }

          let unpacked = try self.unpack(data: data)

          await self.messageValueBatchChannel.send(unpacked)
        }

        self.messageValueBatchChannel.finish()

      } catch {
        self.messageValueBatchChannel.fail(error)
      }
    }
  }

  private let dataSource: MessageDataSource
  private let messageValueBatchChannel = AsyncThrowingChannel<[MessageValue], Error>()
  private var mpac = msgpack_unpacker()
  private var unpacked = msgpack_unpacked()

  private var task: Task<Void, Never>?

  private func unpack(data: Data) throws -> [MessageValue] {
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

    var accumulator = [MessageValue]()

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
        values.append(try self.value(from: element))
      }

      return values

    case MSGPACK_OBJECT_MAP:
      var keyValues = [(key: MessageValue, value: MessageValue)]()

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

public protocol MessageDataSource {
  var data: AnyAsyncThrowingSequence<Data> { get }
}

public typealias MessageValue = Any?

public protocol MessageValueEncodable {
  var messageValueEncoded: MessageValue { get }
}

public enum MessageUnpackError: Error {
  case parseError
  case unexpectedResult
  case unexpectedValueType
}
