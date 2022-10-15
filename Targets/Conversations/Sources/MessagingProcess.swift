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

public class MessagingProcess: AsyncSequence {
  public typealias AsyncIterator = AsyncThrowingChannel<Element, Error>.AsyncIterator
  public typealias Element = Message

  private let channel = AsyncThrowingChannel<Message, Error>()

  public let send: (Message) throws -> Void

  @MainActor
  public init(executableURL: URL, arguments: [String]) {
    // let channel = AsyncThrowingChannel<Message, Error>()
    // self.channel = channel

    let process = Process()
    process.executableURL = executableURL
    process.arguments = arguments

    let inputPipe = Pipe()
    process.standardInput = inputPipe

    self.send = { message in
      do {
        try inputPipe.fileHandleForWriting.write(contentsOf: pack(message.messagePackValue))
      } catch {
        throw "failed writing to process standard input".fail(child: error.fail())
      }
    }

    let outputPipe = Pipe()
    process.standardOutput = outputPipe

    Task {
      var bufferData = Data()

      for await data in AsyncFileData(outputPipe.fileHandleForReading) {
        bufferData += data

        do {
          let messagePackValue: MessagePackValue
          (messagePackValue, bufferData) = try unpack(bufferData)
          let message = try Message(messagePackValue: messagePackValue)
          await channel.send(message)

        } catch MessagePackError.insufficientData {
          continue

        } catch {
          channel.fail("failed parsing buffer data".fail(child: error.fail()))
          return
        }
      }

      channel.finish()
    }

    do {
      try process.run()
    } catch {
      channel.fail("failed starting process".fail(child: error.fail()))
    }
  }

  public func makeAsyncIterator() -> AsyncIterator {
    channel.makeAsyncIterator()
  }
}
