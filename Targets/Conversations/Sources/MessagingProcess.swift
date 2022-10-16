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
import RxSwift

@ProcessActor
public class MessagingProcess {
  public init(executableURL: URL, arguments: [String]) {
    let process = Process()
    process.executableURL = executableURL
    process.arguments = arguments

    process.terminationHandler = { _ in
    }

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
    
    outputPipe.fileHandleForReading.data
      .reduce(Data()) { result, data in
        let newData = result + data
      }

    Task {
      var bufferData = Data()

      for await data in AsyncFileData(outputPipe.fileHandleForReading) {
        bufferData += data

        do {
          let messagePackValue: MessagePackValue
          (messagePackValue, bufferData) = try unpack(bufferData)
          let message = try Message(messagePackValue: messagePackValue)
          await self.channel.send(message)

        } catch MessagePackError.insufficientData {
          continue

        } catch {
          self.channel.fail("failed parsing buffer data".fail(child: error.fail()))
          return
        }
      }

      self.channel.finish()
    }

    do {
      try process.run()
    } catch {
      self.channel.fail("failed starting process".fail(child: error.fail()))
    }
  }

  public typealias AsyncIterator = AsyncThrowingChannel<Element, Error>.AsyncIterator
  public typealias Element = Message

  public let send: (Message) throws -> Void

  public func makeAsyncIterator() -> AsyncIterator {
    self.channel.makeAsyncIterator()
  }

  private let channel = AsyncThrowingChannel<Message, Error>()
}
