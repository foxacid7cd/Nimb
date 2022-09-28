//
//  Unpackable.swift
//  
//
//  Created by Yevhenii Matviienko on 28.09.2022.
//

import MessagePack

public protocol Unpackable {
  init(packed: MessagePackValue) throws
}
