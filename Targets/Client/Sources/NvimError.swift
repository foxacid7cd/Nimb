//
//  NvimError.swift
//
//
//  Created by Yevhenii Matviienko on 29.09.2022.
//

import MessagePack

public struct NvimError: Error, CustomStringConvertible {
  public var payload: MessagePackValue

  public init(payload: MessagePackValue) {
    self.payload = payload
  }

  public var description: String {
    "NvimError: \(payload)."
  }
}
