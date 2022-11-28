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
  
  var packer = msgpack_packer()
  msgpack_packer_init(&packer, &buffer, msgpack_sbuffer_write)
  
  msgpack_pack_array(&packer, 4)
  msgpack_pack_int(&packer, 0)
  msgpack_pack_uint32(&packer, 0)
  
  "nvim_ui_attach"
    .utf8CString
    .withUnsafeBytes { bufferPointer in
      let pointer = bufferPointer.baseAddress!
      
      _ = msgpack_pack_str_with_body(&packer, pointer, strlen(pointer))
    }
  
  msgpack_pack_array(&packer, 3)
  msgpack_pack_int(&packer, 80)
  msgpack_pack_int(&packer, 24)
  
  msgpack_pack_map(&packer, 1)
  
  "override"
    .utf8CString
    .withUnsafeBytes { bufferPointer in
      let pointer = bufferPointer.baseAddress!
      
      msgpack_pack_str_with_body(&packer, pointer, strlen(pointer))
    }
  msgpack_pack_true(&packer)
  
  return Data(bytesNoCopy: buffer.data, count: buffer.size, deallocator: .custom { _, _ in
    msgpack_sbuffer_destroy(&buffer)
  })
}

@MainActor
public func message_unpack(data: Data) {
  var unpacker = msgpack_unpacker()
  msgpack_unpacker_init(&unpacker, Int(MSGPACK_UNPACKER_INIT_BUFFER_SIZE))
  
  if msgpack_unpacker_buffer_capacity(&unpacker) < data.count {
    msgpack_unpacker_reserve_buffer(&unpacker, data.count)
  }
  
  data.withUnsafeBytes { pointer in
    msgpack_unpacker_buffer(&unpacker)
      .initialize(
        from: pointer.baseAddress!
          .assumingMemoryBound(to: CChar.self),
        count: pointer.count
      )
  }
  msgpack_unpacker_buffer_consumed(
    &unpacker,
    data.count
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
