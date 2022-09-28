//
//  MessageConsumer.swift
//  
//
//  Created by Yevhenii Matviienko on 28.09.2022.
//

import Foundation
import MessagePack

public protocol MessageConsumer {
  func consume(message: Message) throws
}

extension FileHandle: MessageConsumer {
  public func consume(message: Message) throws {
    try self.write(contentsOf: pack(message.packed))
  }
}
