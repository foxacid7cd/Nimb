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
  public func pack(encodable: MessageValueEncodable) -> Data {
    self.pack(messageValue: encodable.messageValueEncoded)
  }
  
  @MainActor
  public func pack(messageValue: MessageValue) -> Data {
    self.pack(messageValue)
    
    let data = Data(bytes: sbuf.data, count: sbuf.size)
    msgpack_sbuffer_clear(&sbuf)
    
    return data
  }
  
  @MainActor
  private func pack(_ messageValue: MessageValue) {
    guard let messageValue else {
      msgpack_pack_nil(&pk)
      return
    }
    
    switch messageValue {
    case let value as Bool:
      if value {
        msgpack_pack_true(&pk)
        
      } else {
        msgpack_pack_false(&pk)
      }
      
    case let value as Int:
      msgpack_pack_int64(&pk, Int64(value))
      
    case let value as String:
      value.utf8CString
        .withUnsafeBytes { bufferPointer in
          let pointer = bufferPointer.baseAddress!
          
          _ = msgpack_pack_str_with_body(
            &pk,
            pointer,
            strlen(pointer)
          )
        }
      
    case let value as Double:
      msgpack_pack_float(&pk, Float(value))
      
    case let keyValues as [(key: MessageValue, value: MessageValue)]:
      msgpack_pack_map(&pk, keyValues.count)
      
      for (key, value) in keyValues {
        self.pack(key)
        self.pack(value)
      }
      
    case let value as [MessageValue]:
      msgpack_pack_array(&pk, value.count)
      
      for element in value {
        self.pack(element)
      }
      
    case let value as (data: Data, type: Int8):
      value.data
        .withUnsafeBytes { bufferPointer in
          _ = msgpack_pack_ext_with_body(
            &pk,
            bufferPointer.baseAddress!,
            bufferPointer.count,
            value.type
          )
      }
      
    case let value as Data:
      value.withUnsafeBytes { bufferPointer in
        _ = msgpack_pack_bin_with_body(
          &pk,
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
      
      for i in (0..<Int(object.via.array.size)) {
        let element = object.via.array.ptr.advanced(by: i).pointee
        values.append(try self.value(from: element))
      }
      
      return values
      
    case MSGPACK_OBJECT_MAP:
      var keyValues = [(key: MessageValue, value: MessageValue)]()
      
      for i in (0..<Int(object.via.map.size)) {
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

public typealias MessageValue = Any?

public protocol MessageValueEncodable {
  var messageValueEncoded: MessageValue { get }
}

public enum MessageUnpackError: Error {
  case parseError
  case unexpectedResult
  case unexpectedValueType
}
