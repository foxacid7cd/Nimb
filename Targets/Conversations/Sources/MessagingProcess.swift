//
//  MessagingProcess.swift
//  Conversations
//
//  Created by Yevhenii Matviienko on 30.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AsyncAlgorithms
import Foundation
import Library
import MessagePack

public struct MessagingProcess: AsyncSequence {
  public typealias AsyncIterator = AsyncStream<Element>.Iterator
  public typealias Element = Message

  private let stream: AsyncStream<Message>

  public let send: (Message) async -> Void

  @MainActor
  public init(executableURL: URL, arguments: [String]) {
    let inputMessages = AsyncChannel<Message>()
    
    stream = .init { continuation in
      let process = Process()
      process.executableURL = executableURL
      process.arguments = arguments

      let inputPipe = Pipe()
      process.standardInput = inputPipe

      Task {
        for await message in inputMessages {
          do {
            try inputPipe.fileHandleForWriting.write(contentsOf: pack(message.messagePackValue))
          } catch {
            assertionFailure("failed writing to process standard input with error '\(error)'")
          }
        }
      }

      let outputPipe = Pipe()
      process.standardOutput = outputPipe

      Task {
        do {
          var bufferData = Data()

          for try await data in AsyncFileData(outputPipe.fileHandleForReading) {
            bufferData += data

            do {
              let messagePackValue: MessagePackValue
              (messagePackValue, bufferData) = try unpack(bufferData)
              guard let message = Message(messagePackValue: messagePackValue) else { continue }
              continuation.yield(message)

            } catch MessagePackError.insufficientData {
              continue

            } catch {
              assertionFailure("failed parsing buffer data with error \(error)")
              continuation.finish()
            }
          }
          
          continuation.finish()

        } catch {
          assertionFailure("failed reading process standard output with error \(error)")
          continuation.finish()
        }
      }

      do {
        try process.run()
      } catch {
        assertionFailure("failed starting process with error \(error)")
        continuation.finish()
      }
    }
    send = inputMessages.send(_:)
  }

  public func makeAsyncIterator() -> AsyncIterator {
    stream.makeAsyncIterator()
  }
}
