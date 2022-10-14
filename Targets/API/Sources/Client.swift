//
//  Client.swift
//
//
//  Created by Yevhenii Matviienko on 29.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import Library
import MessagePack
import Procedures

public class Client: AsyncSequence {
  public typealias AsyncIterator = AsyncThrowingStream<Element, Error>.AsyncIterator
  public typealias Element = Event

  public enum Event {
    case notificationReceived(method: Library.Method)
    case standardError(line: String)
    case terminated(exitCode: Int, reason: Process.TerminationReason)
  }

  private let stream: AsyncThrowingStream<Event, Error>

  let request: (Library.Method) async throws -> MessagePackValue

  @MainActor
  public init() {
    let process = ProceduringProcess(
      executableURL: URL(fileURLWithPath: "/bin/zsh"),
      arguments: ["-c", "nvim --embed"]
    )
    stream = .init { continuation in
      Task {
        for await event in process {
          switch event {
            case let .notificationReceived(notification):
              continuation.yield(.notificationReceived(method: notification))

            case let .standardError(line):
              continuation.yield(.standardError(line: line))

            case let .terminated(exitCode, reason):
              continuation.yield(.terminated(exitCode: exitCode, reason: reason))
          }
        }
        continuation.finish()
      }
    }
    request = process.request
  }

  public func makeAsyncIterator() -> AsyncIterator {
    stream.makeAsyncIterator()
  }
}
