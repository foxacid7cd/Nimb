//
//  Notification.swift
//  Library
//
//  Created by Yevhenii Matviienko on 14.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Library

public enum Notification {
  case redraw(uiEvents: [UIEvent])
  case unknown(description: String)

  public init(method: Method) throws {
    switch method.name {
    case "redraw":
      let uiEvents = try method.parameters
        .map { parameter -> UIEvent in
          let uiEventMethod = try Method(messagePackValue: parameter)
          return try .init(method: uiEventMethod)
        }
      self = .redraw(uiEvents: uiEvents)

    default:
      self = .unknown(description: "\(method)")
    }
  }
}
