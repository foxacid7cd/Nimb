//
//  MessagingProcess.swift
//  Conversations
//
//  Created by Yevhenii Matviienko on 30.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import Library
import MessagePack

public struct MessagingProcess: AsyncSequence {
  public typealias AsyncIterator = AsyncThrowingStream<Element, Error>.Iterator
  public typealias Element = Event

  public enum Event {
    case standardOutput(Message)
    case standardError(line: String)
    case terminated(exitCode: Int, reason: Process.TerminationReason)
  }

  private let stream: AsyncThrowingStream<Element, Error>

  @MainActor
  public init(executableURL: URL, arguments: [String]) {
    self.stream = .init { continuation in
      let process = Process()
      process.executableURL = executableURL
      process.arguments = arguments

      let inputPipe = Pipe()
      process.standardInput = inputPipe

      let outputPipe = Pipe()
      process.standardOutput = outputPipe

      let errorPipe = Pipe()
      process.standardError = errorPipe

      Task {
        do {
          var bufferData = Data()

          for try await data in AsyncFileData(outputPipe.fileHandleForReading) {
            bufferData += data

            do {
              let messagePackValue: MessagePackValue
              (messagePackValue, bufferData) = try unpack(bufferData)
              let message = try Message(messagePackValue: messagePackValue)
              continuation.yield(.standardOutput(message))

            } catch MessagePackError.insufficientData {
              continue

            } catch {
              continuation.finish(throwing: error)
            }
          }

          continuation.finish()

        } catch {
          continuation.finish(throwing: error)
        }
      }

      Task {
        do {
          for try await data in AsyncFileData(errorPipe.fileHandleForReading) {
            let string = String(data: data, encoding: .utf8)!
            continuation.yield(.standardError(line: string))
          }

          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }

      do {
        try process.run()
      } catch {
        continuation.finish(throwing: error)
      }
    }
  }

  public func makeAsyncIterator() -> AsyncIterator {
    stream.makeAsyncIterator()
  }
}
