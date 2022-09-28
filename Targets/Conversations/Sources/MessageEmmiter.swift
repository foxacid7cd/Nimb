//
//  MessageEmmiter.swift
//  
//
//  Created by Yevhenii Matviienko on 28.09.2022.
//

import Foundation
import MessagePack

public protocol MessageEmitter {
  var messages: AsyncMessages { get }
}

extension FileHandle: MessageEmitter {
  @MainActor
  public var messages: AsyncMessages {
    .init(fileHandle: self)
  }
}
