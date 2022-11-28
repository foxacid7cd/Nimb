//
//  MessagePacker.swift
//  MessagePack
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Foundation
import SwiftUI

public class MessagePacker {
  var sbuf = msgpack_sbuffer()
  var pk = msgpack_packer()
  
  public init() {
    msgpack_sbuffer_init(&sbuf)
    msgpack_packer_init(&pk, &sbuf, msgpack_sbuffer_write)
  }
  
  deinit {
    msgpack_sbuffer_destroy(&sbuf)
  }
  
  @MainActor
  public func pack(value: MessageValue) -> Data {
    value.pack(to: self)
    
    let data = Data(bytes: sbuf.data, count: sbuf.size)
    msgpack_sbuffer_clear(&sbuf)
    
    return data
  }
}

public class MessageUnpacker {
  var mpac = msgpack_unpacker()
  var unpacked = msgpack_unpacked()
  
  public init() {
    msgpack_unpacker_init(&mpac, Int(MSGPACK_UNPACKER_INIT_BUFFER_SIZE))
    msgpack_unpacked_init(&unpacked)
  }
  
  deinit {
    msgpack_unpacked_destroy(&unpacked)
    msgpack_unpacker_destroy(&mpac)
  }
  
  @MainActor
  public func unpack(data: Data) throws -> [MessageValue] {
    if msgpack_unpacker_buffer_capacity(&mpac) < data.count {
      msgpack_unpacker_reserve_buffer(&mpac, data.count)
    }
    
    data.withUnsafeBytes { pointer in
      msgpack_unpacker_buffer(&mpac)!
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
        let value = try self.value(from: unpacked.data)
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
  
  private func value(from object: msgpack_object) throws -> MessageValue {
    switch object.type {
    case MSGPACK_OBJECT_NIL:
      return MessageNilValue()
      
    case MSGPACK_OBJECT_BOOLEAN:
      return MessageBooleanValue(
        boolean: object.via.boolean
      )
      
    case MSGPACK_OBJECT_POSITIVE_INTEGER:
      return MessageInt64Value(Int64(object.via.u64))
      
    case MSGPACK_OBJECT_NEGATIVE_INTEGER:
      return MessageInt64Value(object.via.i64)
      
    case MSGPACK_OBJECT_STR:
      let str = object.via.str
      let size = Int(str.size)
      
      return MessageStringValue(
        String(unsafeUninitializedCapacity: size, initializingUTF8With: { buffer in
          let pointer = buffer.baseAddress!
          
          memcpy(pointer, str.ptr, size)
          return size
        })
      )
      
    case MSGPACK_OBJECT_ARRAY:
      var values = [MessageValue]()
      
      for i in (0..<Int(object.via.array.size)) {
        let element = object.via.array.ptr.advanced(by: i).pointee
        values.append(try self.value(from: element))
      }
      
      return MessageArrayValue(values)
      
    case MSGPACK_OBJECT_MAP:
      var keyValues = [(key: MessageValue, value: MessageValue)]()
      
      for i in (0..<Int(object.via.map.size)) {
        let element = object.via.map.ptr.advanced(by: i).pointee
        keyValues.append((
          try self.value(from: element.key),
          try self.value(from: element.val)
        ))
      }
      
      return MessageMapValue(keyValues)
      
    case MSGPACK_OBJECT_FLOAT, MSGPACK_OBJECT_FLOAT32:
      return MessageDoubleValue(object.via.f64)
      
    case MSGPACK_OBJECT_BIN:
      let bin = object.via.bin
      let data = Data(bytes: bin.ptr, count: Int(bin.size))
      return MessageBinaryValue(data)
      
    case MSGPACK_OBJECT_EXT:
      let ext = object.via.ext
      let data = Data(bytes: ext.ptr, count: Int(ext.size))
      return MessageExtValue(data: data, type: ext.type)
      
    default:
      throw MessageUnpackError.unexpectedValueType
    }
  }
}

public protocol MessageValue {
  func pack(to packer: MessagePacker)
}

public struct DeferredMessageValue: MessageValue {
  var deferred: @Sendable () -> MessageValue
  
  public init(_ deferred: @Sendable @escaping () -> MessageValue) {
    self.deferred = deferred
  }
  
  public func pack(to packer: MessagePacker) {
    self.deferred().pack(to: packer)
  }
}

public struct MessageStringValue: MessageValue, ExpressibleByStringLiteral {
  var string: any StringProtocol
  
  public init(_ string: any StringProtocol) {
    self.string = string
  }
  
  public init(stringLiteral value: StringLiteralType) {
    self.string = value
  }
  
  public func pack(to packer: MessagePacker) {
    String(string).utf8CString
      .withUnsafeBytes { bufferPointer in
        let pointer = bufferPointer.baseAddress!
        
        _ = msgpack_pack_str_with_body(
          &packer.pk,
          pointer,
          strlen(pointer)
        )
      }
  }
}

public struct MessageUInt32Value: MessageValue, ExpressibleByIntegerLiteral {
  var value: UInt32
  
  public init(_ value: UInt32) {
    self.value = value
  }
  
  public init(integerLiteral value: IntegerLiteralType) {
    self.value = UInt32(value)
  }
  
  public func pack(to packer: MessagePacker) {
    msgpack_pack_uint32(&packer.pk, value)
  }
}

public struct MessageInt64Value: MessageValue, ExpressibleByIntegerLiteral {
  var value: Int64
  
  public init(_ value: Int64) {
    self.value = value
  }
  
  public init(integerLiteral value: IntegerLiteralType) {
    self.value = Int64(value)
  }
  
  public func pack(to packer: MessagePacker) {
    msgpack_pack_int64(&packer.pk, value)
  }
}

public struct MessageArrayValue: MessageValue, ExpressibleByArrayLiteral {
  var elements = [MessageValue]()
  
  public init(_ elements: [MessageValue]) {
    self.elements = elements
  }
  
  public init(arrayLiteral elements: MessageValue...) {
    self.elements = elements
  }
  
  public func pack(to packer: MessagePacker) {
    msgpack_pack_array(&packer.pk, elements.count)
    
    for element in elements {
      element.pack(to: packer)
    }
  }
}

public struct MessageMapValue: MessageValue, ExpressibleByDictionaryLiteral {
  var keyValues = [(key: MessageValue, value: MessageValue)]()
  
  public init(_ keyValues: [(key: MessageValue, value: MessageValue)]) {
    self.keyValues = keyValues
  }
  
  public init(dictionaryLiteral elements: (Key, Value)...) {
    self.init(elements)
  }
  
  public func pack(to packer: MessagePacker) {
    msgpack_pack_map(&packer.pk, self.keyValues.count)
    
    for (key, value) in self.keyValues {
      key.pack(to: packer)
      value.pack(to: packer)
    }
  }
  
  public typealias Key = MessageValue
  public typealias Value = MessageValue
}

public struct MessageNilValue: MessageValue, ExpressibleByNilLiteral {
  public init() {}
  
  public init(nilLiteral: ()) {
    self.init()
  }
  
  public func pack(to packer: MessagePacker) {
    msgpack_pack_nil(&packer.pk)
  }
}

public struct MessageBooleanValue: MessageValue, ExpressibleByBooleanLiteral {
  var boolean: Bool
  
  public init(boolean: Bool) {
    self.boolean = boolean
  }
  
  public init(booleanLiteral value: Bool) {
    self.boolean = value
  }
  
  public func pack(to packer: MessagePacker) {
    if boolean {
      msgpack_pack_true(&packer.pk)
      
    } else {
      msgpack_pack_false(&packer.pk)
    }
  }
}

public struct MessageDoubleValue: MessageValue, ExpressibleByFloatLiteral {
  var double: Double
  
  public init(_ double: Double) {
    self.double = double
  }
  
  public init(floatLiteral value: FloatLiteralType) {
    self.double = value
  }
  
  public func pack(to packer: MessagePacker) {
    msgpack_pack_double(&packer.pk, double)
  }
}

public struct MessageBinaryValue: MessageValue {
  var data: Data
  
  public init(_ data: Data) {
    self.data = data
  }
  
  public func pack(to packer: MessagePacker) {
    data.withUnsafeBytes { bufferPointer in
      _ = msgpack_pack_bin_with_body(
        &packer.pk,
        bufferPointer.baseAddress!,
        bufferPointer.count
      )
    }
  }
}

public struct MessageExtValue: MessageValue {
  var data: Data
  var type: Int8
  
  public init(data: Data, type: Int8) {
    self.data = data
    self.type = type
  }
  
  public func pack(to packer: MessagePacker) {
    data.withUnsafeBytes { bufferPointer in
      _ = msgpack_pack_ext_with_body(
        &packer.pk,
        bufferPointer.baseAddress!,
        bufferPointer.count, type
      )
    }
  }
}

public enum MessageUnpackError: Error {
  case parseError
  case unexpectedResult
  case unexpectedValueType
}
