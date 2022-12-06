//
//  File.swift
//  
//
//  Created by Yevhenii Matviienko on 06.12.2022.
//

import Foundation
import MessagePack

public actor UIEvents: AsyncSequence {
  public init(_ rpc: RPC) {
    self.rpc = rpc
  }
  
  nonisolated public func makeAsyncIterator() -> AsyncIterator {
    .init {
      for await notification in await self.rpc.notifications {
        if Task.isCancelled {
          break
        }
        
        switch notification.method {
        case "redraw":
          for parameter in notification.parameters {
            guard
              let arrayValue = parameter as? [MessageValue],
              !arrayValue.isEmpty,
              let uiEventName = arrayValue[0] as? String
            else {
              assertionFailure()
              continue
            }
          }
          
        default:
          break
        }
      }
      
      return nil
    }
  }
  
  public typealias Element = UIEvent
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    public mutating func next() async throws -> UIEvent? {
      try await _next()
    }
    
    var _next: () async throws -> UIEvent?
  }
  
  private let rpc: RPC
}
