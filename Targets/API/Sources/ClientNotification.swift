//
//  ClientNotificationn.swift
//  Library
//
//  Created by Yevhenii Matviienko on 14.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Conversations
import Library
import MessagePack

public enum ClientNotification {
  case redraw(uiEvents: [UIEvent])
  
  public init?(messageNotification: MessageNotification) {
    switch messageNotification.method {
    case "redraw":
      var uiEvents = [UIEvent]()
      
      for parameters in messageNotification.parametersArray {
        guard let method = parameters.first?.stringValue else {
          assertionFailure("first element is expected to be a string representing UI event method")
          return nil
        }
        
        guard let uiEvent = UIEvent(method: method, parametersArray: parameters.dropFirst().normalizedToParametersArray) else {
          return nil
        }
        
        uiEvents.append(uiEvent)
      }
      
      self = .redraw(uiEvents: uiEvents)
      
    default:
      assertionFailure("unknown notification method '\(messageNotification.method)'")
      return nil
    }
  }
}
