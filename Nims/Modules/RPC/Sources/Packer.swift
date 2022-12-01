//
//  Packer.swift
//  MessagePack
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import AsyncAlgorithms
import Backbone
import Foundation

public protocol PackerProtocol {
  func pack(value: Value) async throws
}

public protocol DataDestination {
  func write(data: Data) async throws
}

public actor Packer: PackerProtocol {
  public init(dataDestination: DataDestination) {
    self.dataDestination = dataDestination

    msgpack_sbuffer_init(&self.sbuf)
    msgpack_packer_init(&self.pk, &self.sbuf, msgpack_sbuffer_write)
  }

  deinit {
    msgpack_sbuffer_destroy(&sbuf)
  }

  public func pack(value: Value) async throws {
    self.msgpack(value)

    let data = Data(bytes: sbuf.data, count: self.sbuf.size)
    msgpack_sbuffer_clear(&self.sbuf)

    try await self.dataDestination.write(data: data)
  }

  private let dataDestination: DataDestination
  private var sbuf = msgpack_sbuffer()
  private var pk = msgpack_packer()

  private func msgpack(_ value: Value) {
    guard let value else {
      msgpack_pack_nil(&self.pk)
      return
    }

    switch value {
    case let casted as Bool:
      if casted {
        msgpack_pack_true(&self.pk)

      } else {
        msgpack_pack_false(&self.pk)
      }

    case let casted as Int:
      msgpack_pack_int64(&self.pk, Int64(casted))

    case let casted as String:
      casted.utf8CString
        .withUnsafeBytes { bufferPointer in
          let pointer = bufferPointer.baseAddress!

          _ = msgpack_pack_str_with_body(
            &self.pk,
            pointer,
            strlen(pointer)
          )
        }

    case let casted as Double:
      msgpack_pack_float(&self.pk, Float(casted))

    case let casted as Map:
      msgpack_pack_map(&self.pk, casted.count)

      for (key, value) in casted {
        self.msgpack(key)
        self.msgpack(value)
      }

    case let casted as [Value]:
      msgpack_pack_array(&self.pk, casted.count)

      for element in casted {
        self.msgpack(element)
      }

    case let casted as Ext:
      casted.data.withUnsafeBytes { buffer in
        _ = msgpack_pack_ext_with_body(
          &self.pk,
          buffer.baseAddress!,
          buffer.count,
          casted.type
        )
      }

    case let casted as Data:
      casted.withUnsafeBytes { buffer in
        _ = msgpack_pack_bin_with_body(
          &self.pk,
          buffer.baseAddress!,
          buffer.count
        )
      }

    default:
      fatalError("Unsupported type: \(value)")
    }
  }
}
