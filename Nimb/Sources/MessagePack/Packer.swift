// SPDX-License-Identifier: MIT

import Foundation

public class Packer {
  private var sbuf = msgpack_sbuffer()
  private var pk = msgpack_packer()

  public init() {
    msgpack_sbuffer_init(&sbuf)
    msgpack_packer_init(&pk, &sbuf, msgpack_sbuffer_write)
  }

  deinit {
    msgpack_sbuffer_destroy(&sbuf)
  }

  public func pack(_ value: Value) -> Data {
    process(value)

    defer { msgpack_sbuffer_clear(&sbuf) }
    return .init(bytes: sbuf.data, count: sbuf.size)
  }

  private func process(_ value: Value) {
    switch value {
    case let .boolean(boolean):
      if boolean {
        msgpack_pack_true(&pk)

      } else {
        msgpack_pack_false(&pk)
      }

    case let .integer(integer):
      msgpack_pack_int64(&pk, Int64(integer))

    case let .string(string):
      string.data(using: .utf8)!
        .withUnsafeBytes { buffer in
          _ = msgpack_pack_str_with_body(
            &self.pk,
            buffer.baseAddress!,
            buffer.count
          )
        }

    case let .float(double): msgpack_pack_float(&pk, Float(double))

    case let .dictionary(dictionary):
      msgpack_pack_map(&pk, dictionary.count)

      for (key, value) in dictionary {
        process(key)
        process(value)
      }

    case let .array(array):
      msgpack_pack_array(&pk, array.count)

      for element in array {
        process(element)
      }

    case let .ext(type, data):
      data.withUnsafeBytes { buffer in
        _ = msgpack_pack_ext_with_body(
          &self.pk,
          buffer.baseAddress!,
          buffer.count,
          type
        )
      }

    case let .binary(data):
      data.withUnsafeBytes { buffer in
        _ = msgpack_pack_bin_with_body(
          &self.pk,
          buffer.baseAddress!,
          buffer.count
        )
      }

    case .nil: msgpack_pack_nil(&pk)
    }
  }
}
