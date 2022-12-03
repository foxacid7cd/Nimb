// Copyright © 2022 foxacid7cd. All rights reserved.

import Backbone
import Foundation
import msgpack

public protocol PackerProtocol {
  func pack(_ value: Value) async -> Data
}

public actor Packer: PackerProtocol {
  public init() {
    msgpack_sbuffer_init(&sbuf)
    msgpack_packer_init(&pk, &sbuf, msgpack_sbuffer_write)
  }

  deinit {
    msgpack_sbuffer_destroy(&sbuf)
  }

  public func pack(_ value: Value) -> Data {
    msgpack(value)

    let data = Data(bytes: sbuf.data, count: sbuf.size)
    msgpack_sbuffer_clear(&sbuf)

    return data
  }

  private var sbuf = msgpack_sbuffer()
  private var pk = msgpack_packer()

  private func msgpack(_ value: Value) {
    guard let value
    else {
      msgpack_pack_nil(&pk)
      return
    }

    switch value {
    case let value as Bool:
      if value {
        msgpack_pack_true(&pk)
      } else {
        msgpack_pack_false(&pk)
      }

    case let value as Int:
      msgpack_pack_int64(&pk, Int64(value))

    case let value as String:
      value.data(using: .utf8)!
        .withUnsafeBytes { buffer in
          let pointer = buffer.baseAddress!

          _ = msgpack_pack_str_with_body(
            &self.pk,
            pointer,
            strlen(pointer)
          )
        }

    case let value as Double:
      msgpack_pack_float(&pk, Float(value))

    case let value as Map:
      msgpack_pack_map(&pk, value.count)

      for keyValue in value {
        msgpack(keyValue.key)
        msgpack(keyValue.value)
      }

    case let value as [Value]:
      msgpack_pack_array(&pk, value.count)

      for element in value {
        msgpack(element)
      }

    case let value as Ext:
      value.data.withUnsafeBytes { buffer in
        _ = msgpack_pack_ext_with_body(
          &self.pk,
          buffer.baseAddress!,
          buffer.count,
          value.type
        )
      }

    case let value as Data:
      value.withUnsafeBytes { buffer in
        _ = msgpack_pack_bin_with_body(
          &self.pk,
          buffer.baseAddress!,
          buffer.count
        )
      }

    default:
      assertionFailure(
        "Sending value \(value)' of invalid msgpack type '\(String(reflecting: value.self))"
      )
      msgpack_pack_nil(&pk)
    }
  }
}
