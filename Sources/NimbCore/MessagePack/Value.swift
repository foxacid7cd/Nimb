// SPDX-License-Identifier: MIT

import Foundation
import msgpack_c

public enum Value: Sendable, Hashable, ExpressibleByStringLiteral,
  ExpressibleByBooleanLiteral,
  ExpressibleByNilLiteral,
  ExpressibleByDictionaryLiteral
{
  case integer(Int)
  case float(Double)
  case boolean(Bool)
  case string(String)
  case array([Value])
  case dictionary([Value: Value])
  case binary(Data)
  case ext(type: Int8, data: Data)
  /// A grid_line cell payload, decoded straight off the wire rather than into a
  /// tree of Values, since it is the bulk of what Neovim sends. Inbound only.
  case cellRuns([RawCellRun])
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

  public init(dictionaryLiteral elements: (Value, Value)...) {
    var dictionary = [Value: Value](minimumCapacity: elements.count)
    for (key, value) in elements {
      dictionary[key] = value
    }
    self = .dictionary(dictionary)
  }

  init(
    _ object: msgpack_object,
  ) {
    switch object.type {
    case MSGPACK_OBJECT_NEGATIVE_INTEGER,
         MSGPACK_OBJECT_POSITIVE_INTEGER: self = .integer(Int(object.via.i64))

    case MSGPACK_OBJECT_FLOAT,
         MSGPACK_OBJECT_FLOAT32: self = .float(object.via.f64)

    case MSGPACK_OBJECT_BOOLEAN: self = .boolean(object.via.boolean)

    case MSGPACK_OBJECT_STR:
      let str = object.via.str
      let size = Int(str.size)

      let string = String(
        unsafeUninitializedCapacity: size,
        initializingUTF8With: { buffer in
          memcpy(
            buffer.baseAddress!,
            str.ptr,
            size,
          )
          return size
        },
      )
      self = .string(string)

    case MSGPACK_OBJECT_ARRAY:
      let cArray = object.via.array

      // The count is known up front, so the buffer is allocated once and
      // written in place rather than grown by appending.
      let count = Int(cArray.size)
      self = .array([Value](unsafeUninitializedCapacity: count) { buffer, initialized in
        for index in 0 ..< count {
          buffer.initializeElement(at: index, to: Value(cArray.ptr.advanced(by: index).pointee))
        }
        initialized = count
      })

    case MSGPACK_OBJECT_MAP:
      let map = object.via.map

      let count = Int(map.size)
      var dictionary = [Value: Value](minimumCapacity: count)

      for index in 0 ..< count {
        let kv = map.ptr.advanced(by: index).pointee

        let key = Value(kv.key)
        let value = Value(kv.val)
        dictionary[key] = value
      }

      self = .dictionary(dictionary)

    case MSGPACK_OBJECT_BIN:
      let bin = object.via.bin

      let data = Data(bytes: UnsafeRawPointer(bin.ptr), count: Int(bin.size))
      self = .binary(data)

    case MSGPACK_OBJECT_EXT:
      let ext = object.via.ext

      self = .ext(
        type: ext.type,
        data: .init(bytes: UnsafeRawPointer(ext.ptr), count: Int(ext.size)),
      )

    case MSGPACK_OBJECT_NIL: self = .nil

    default: preconditionFailure(
        "Not implemented behavior for type \(object.type)",
      )
    }
  }

  /// Converts a whole RPC message, taking the grid_line shortcut where it
  /// applies and falling through to the generic conversion where it does not.
  init(message object: msgpack_object) {
    guard
      object.type == MSGPACK_OBJECT_ARRAY,
      object.via.array.size == 3,
      let items = object.via.array.ptr,
      items[0].type == MSGPACK_OBJECT_POSITIVE_INTEGER,
      items[0].via.u64 == 2,
      Self.isString(items[1], "redraw"),
      items[2].type == MSGPACK_OBJECT_ARRAY
    else {
      self = .init(object)
      return
    }

    let rawBatches = items[2].via.array
    let batchesCount = Int(rawBatches.size)
    let batches = [Value](unsafeUninitializedCapacity: batchesCount) { buffer, initialized in
      for index in 0 ..< batchesCount {
        buffer.initializeElement(
          at: index,
          to: Value(redrawBatch: rawBatches.ptr.advanced(by: index).pointee),
        )
      }
      initialized = batchesCount
    }

    self = .array([.integer(2), .string("redraw"), .array(batches)])
  }

  /// One `[name, event, event, ...]` batch.
  private init(redrawBatch object: msgpack_object) {
    guard
      object.type == MSGPACK_OBJECT_ARRAY,
      object.via.array.size >= 1,
      let items = object.via.array.ptr,
      Self.isString(items[0], "grid_line")
    else {
      self = .init(object)
      return
    }

    let count = Int(object.via.array.size)
    self = .array([Value](unsafeUninitializedCapacity: count) { buffer, initialized in
      buffer.initializeElement(at: 0, to: .string("grid_line"))
      for index in 1 ..< count {
        buffer.initializeElement(
          at: index,
          to: Value(gridLineEvent: items[index]),
        )
      }
      initialized = count
    })
  }

  /// One grid_line event: `[grid, row, colStart, cells, wrap]`.
  private init(gridLineEvent object: msgpack_object) {
    guard
      object.type == MSGPACK_OBJECT_ARRAY,
      object.via.array.size == 5,
      let items = object.via.array.ptr,
      items[3].type == MSGPACK_OBJECT_ARRAY,
      let runs = Self.cellRuns(items[3])
    else {
      self = .init(object)
      return
    }

    self = .array([
      .init(items[0]),
      .init(items[1]),
      .init(items[2]),
      .cellRuns(runs),
      .init(items[4]),
    ])
  }

  /// The cell array itself. nil when any entry is not `[text]`, `[text, hl]` or
  /// `[text, hl, repeat]`, so the caller can fall back rather than invent data.
  private static func cellRuns(_ object: msgpack_object) -> [RawCellRun]? {
    let array = object.via.array
    let count = Int(array.size)
    var runs = [RawCellRun]()
    runs.reserveCapacity(count)

    for index in 0 ..< count {
      let entry = array.ptr.advanced(by: index).pointee
      guard
        entry.type == MSGPACK_OBJECT_ARRAY,
        (1 ... 3).contains(Int(entry.via.array.size)),
        let fields = entry.via.array.ptr,
        fields[0].type == MSGPACK_OBJECT_STR
      else {
        return nil
      }

      let size = Int(entry.via.array.size)
      var highlightID: Int?
      var repeatCount: Int?

      if size > 1 {
        guard fields[1].type == MSGPACK_OBJECT_POSITIVE_INTEGER else {
          return nil
        }
        highlightID = Int(fields[1].via.u64)
      }
      if size > 2 {
        guard fields[2].type == MSGPACK_OBJECT_POSITIVE_INTEGER else {
          return nil
        }
        repeatCount = Int(fields[2].via.u64)
      }

      runs.append(
        .init(
          text: Self.string(fields[0]),
          highlightID: highlightID,
          repeatCount: repeatCount,
        ),
      )
    }

    return runs
  }

  private static func string(_ object: msgpack_object) -> String {
    let str = object.via.str
    let size = Int(str.size)
    return String(
      unsafeUninitializedCapacity: size,
      initializingUTF8With: { buffer in
        memcpy(buffer.baseAddress!, str.ptr, size)
        return size
      },
    )
  }

  private static func isString(_ object: msgpack_object, _ expected: String) -> Bool {
    guard object.type == MSGPACK_OBJECT_STR else {
      return false
    }
    let str = object.via.str
    let size = Int(str.size)
    guard size == expected.utf8.count else {
      return false
    }
    return expected.utf8.withContiguousStorageIfAvailable { expectedBytes in
      memcmp(str.ptr, expectedBytes.baseAddress!, size) == 0
    } ?? false
  }
}

/// One run of identical cells as Neovim sends it: text, the highlight it
/// switches to, and how many columns it covers.
@PublicInit
public struct RawCellRun: Sendable, Hashable {
  public var text: String
  public var highlightID: Int? = nil
  public var repeatCount: Int? = nil
}

/// The `data` parameter of a grid_line event. Accepts both the fast-path and
/// the generic representation, so the generated decoder keeps working.
@PublicInit
public struct RawCellRuns: Sendable, Hashable {
  public var runs: [RawCellRun]

  public init?(_ value: Value) {
    switch value {
    case let .cellRuns(runs):
      self.runs = runs

    case let .array(values):
      var runs = [RawCellRun]()
      runs.reserveCapacity(values.count)
      for value in values {
        guard
          case let .array(fields) = value,
          (1 ... 3).contains(fields.count),
          case let .string(text) = fields[0]
        else {
          return nil
        }
        var highlightID: Int?
        var repeatCount: Int?
        if fields.count > 1 {
          guard case let .integer(value) = fields[1] else {
            return nil
          }
          highlightID = value
        }
        if fields.count > 2 {
          guard case let .integer(value) = fields[2] else {
            return nil
          }
          repeatCount = value
        }
        runs.append(.init(text: text, highlightID: highlightID, repeatCount: repeatCount))
      }
      self.runs = runs

    default:
      return nil
    }
  }
}

public extension Value {
  /// Decodes a homogeneous array, failing as a whole if any element does, for
  /// the `ArrayOf(...)` parameters the API metadata describes.
  static func decodeArray<Element>(
    _ value: Value,
    _ decodeElement: (Value) -> Element?,
  )
    -> [Element]?
  {
    guard case let .array(values) = value else {
      return nil
    }
    var result = [Element]()
    result.reserveCapacity(values.count)
    for value in values {
      guard let element = decodeElement(value) else {
        return nil
      }
      result.append(element)
    }
    return result
  }
}

/// Optional accessors for the payload of each case, replacing @CasePathable.
/// The `.string` subscript form is gone.
public extension Value {
  var integer: Int? {
    if case let .integer(value) = self {
      value
    } else {
      nil
    }
  }

  var float: Double? {
    if case let .float(value) = self {
      value
    } else {
      nil
    }
  }

  var boolean: Bool? {
    if case let .boolean(value) = self {
      value
    } else {
      nil
    }
  }

  var string: String? {
    if case let .string(value) = self {
      value
    } else {
      nil
    }
  }

  var array: [Value]? {
    if case let .array(value) = self {
      value
    } else {
      nil
    }
  }

  var dictionary: [Value: Value]? {
    if case let .dictionary(value) = self {
      value
    } else {
      nil
    }
  }

  var binary: Data? {
    if case let .binary(value) = self {
      value
    } else {
      nil
    }
  }

  var ext: (type: Int8, data: Data)? {
    if case let .ext(type, data) = self {
      (type: type, data: data)
    } else {
      nil
    }
  }

  /// Not named `nil`, which is not a valid property name.
  var isNil: Bool {
    if case .nil = self {
      true
    } else {
      false
    }
  }
}
