//
//  MessagePack.swift
//  MessagePack
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Foundation
import OSLog

public func message_pack() -> Data {
  var buffer = msgpack_sbuffer()
  msgpack_sbuffer_init(&buffer)
  
  defer { msgpack_sbuffer_destroy(&buffer) }
  
  var packer = msgpack_packer()
  msgpack_packer_init(&packer, &buffer, msgpack_sbuffer_write)
  
  msgpack_pack_array(&packer, 4)
  msgpack_pack_uint32(&packer, 0)
  msgpack_pack_uint32(&packer, 1)
  
  var method = "nvim_ui_attach"
  let methodCopy = method.withUTF8 { pointer in
    return strdup(pointer.baseAddress!)!
  }
  msgpack_pack_bin_with_body(&packer, methodCopy, strlen(methodCopy))
  //msgpack_pack_str_with_body(&packer, methodCopy, strlen(methodCopy))
  
  msgpack_pack_array(&packer, 3)
  msgpack_pack_uint32(&packer, 80)
  msgpack_pack_uint32(&packer, 24)
  
  msgpack_pack_map(&packer, 1)
  
  var option = "override"
  let optionCopy = option.withUTF8 { pointer in
    return strdup(pointer.baseAddress!)!
  }
  msgpack_pack_bin_with_body(&packer, optionCopy, strlen(optionCopy))
  //msgpack_pack_str_with_body(&packer, optionCopy, strlen(optionCopy))
  msgpack_pack_true(&packer)
  
  return Data(bytes: buffer.data, count: buffer.size)
}

public func message_unpack(data: Data) {
  data.withUnsafeBytes { pointer in
    var unpacker = msgpack_unpacker()
    msgpack_unpacker_init(&unpacker, Int(MSGPACK_UNPACKER_INIT_BUFFER_SIZE))
    
    if msgpack_unpacker_buffer_capacity(&unpacker) < pointer.count {
      msgpack_unpacker_reserve_buffer(&unpacker, pointer.count)
    }
    
    memcpy(
      msgpack_unpacker_buffer(&unpacker),
      pointer.baseAddress!,
      pointer.count
    )
    msgpack_unpacker_buffer_consumed(
      &unpacker,
      pointer.count
    )
    
    var unpacked = msgpack_unpacked()
    msgpack_unpacked_init(&unpacked)
    
    var result = MSGPACK_UNPACK_SUCCESS
    
    loop: while true {
      result = msgpack_unpacker_next(&unpacker, &unpacked)
      
      switch result {
      case MSGPACK_UNPACK_SUCCESS:
        let object = unpacked.data
        msgpack_object_print(stdout, object)
        print()
        
      case MSGPACK_UNPACK_CONTINUE:
        os_log("MSGPACK_UNPACK_CONTINUE")
        break loop
        
      case MSGPACK_UNPACK_PARSE_ERROR:
        os_log("MSGPACK_UNPACK_PARSE_ERROR")
        break loop
        
      default:
        os_log("MSGPACK_UNPACK_UNKNOWN")
        break loop
      }
    }
    
    msgpack_unpacked_destroy(&unpacked)
    msgpack_unpacker_destroy(&unpacker)
  }
}
