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
  
  public func pack(value: MessageValue) -> Data {
    value.pack(to: self)
    
    let data = Data(bytes: sbuf.data, count: sbuf.size)
    msgpack_sbuffer_clear(&sbuf)
    
    return data
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
  private static let shared = MessageNilValue()
  
  public init() {
    self = .shared
  }
  
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
