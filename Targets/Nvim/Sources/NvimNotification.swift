//
//  NvimNotification.swift
//  Library
//
//  Created by Yevhenii Matviienko on 14.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Library
import MessagePack

public enum NvimNotification {
  case redraw(uiEvents: [UIEvent])

  public init(notification: Notification) throws {
    switch notification.method {
    case "redraw":
      var uiEvents = [UIEvent]()

      for parameters in notification.parameters {
        guard let method = parameters.first?.stringValue else {
          throw "first element is expected to be a string representing UI event method"
            .fail()
        }

        do {
          let uiEvent = try UIEvent(
            method: method,
            parametersArray: parameters.dropFirst().normalizedToParametersArray
          )
          uiEvents.append(uiEvent)

        } catch {
          throw "first".fail(child: error.fail())
        }
      }

      self = .redraw(uiEvents: uiEvents)

    default:
      throw "unknown notification method \(notification.method)"
        .fail()
    }
  }
}
