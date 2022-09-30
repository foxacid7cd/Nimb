//
//  AsyncMessages.swift
//
//
//  Created by Yevhenii Matviienko on 28.09.2022.
//

import Combine
import Foundation
import MessagePack

public class AsyncMessages: AsyncSequence {
  public typealias Element = Message
  
  public class AsyncIterator: AsyncIteratorProtocol {
    public typealias Element = Message
    
    private let fileHandle: FileHandle
    private var messages = [Message]()
    private let messagesUpdatedSubject: PassthroughSubject<Void, Error>
    
    private var messagesUpdated: AsyncThrowingPublisher<some Publisher> {
      return .init(messagesUpdatedSubject)
    }
    
    @MainActor
    init(fileHandle: FileHandle) {
      self.fileHandle = fileHandle
      
      let messagesUpdatedSubject = PassthroughSubject<Void, Error>()
      self.messagesUpdatedSubject = messagesUpdatedSubject
      
      let bufferSize = 1024 * 1024
      withUnsafeTemporaryAllocation(byteCount: bufferSize, alignment: MemoryLayout<Date>.alignment) { [weak self] bufferPointer in
        let bufferData = Data(bytesNoCopy: bufferPointer.baseAddress!, count: bufferSize, deallocator: .none)
        let pointer = bufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
        var endIndex = 0
        
        fileHandle.readabilityHandler = { fileHandle in
          let data = fileHandle.availableData
          let bytesCount = data.count
          
          data.copyBytes(to: pointer.advanced(by: endIndex), count: bytesCount)
          endIndex += bytesCount
          
          var subdata = Subdata(data: bufferData, startIndex: 0, endIndex: endIndex)
          do {
            guard let self else {
              throw NSError(domain: "", code: 0)
            }
            
            while true {
              let messagePackValue: MessagePackValue
              (messagePackValue, subdata) = try unpack(subdata)
              self.messages.append(try Message(messagePackValue: messagePackValue))
              messagesUpdatedSubject.send(())
            }
          } catch MessagePackError.insufficientData {
            let remainder = subdata.data
            remainder.copyBytes(to: pointer, count: remainder.count)
            endIndex = remainder.count
          } catch {
            fileHandle.readabilityHandler = nil
            messagesUpdatedSubject.send(completion: .failure(error))
          }
        }
      }
    }
    
    @MainActor
    public func next() async throws -> Message? {
      while true {
        if !messages.isEmpty {
          return messages.removeFirst()
        }
        var iterator = messagesUpdated.makeAsyncIterator()
        _ = try await iterator.next()
      }
    }
  }
  
  var fileHandle: FileHandle
  
  public init(fileHandle: FileHandle) {
    self.fileHandle = fileHandle
  }
  
  deinit {
    fileHandle.readabilityHandler = nil
  }
  
  @MainActor
  public func makeAsyncIterator() -> AsyncIterator {
    .init(fileHandle: fileHandle)
  }
}
