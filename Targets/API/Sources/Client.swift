//
//  Client.swift
//
//
//  Created by Yevhenii Matviienko on 29.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Conversations
import Foundation
import Library
import MessagePack

public class Client: AsyncSequence {
  @MainActor
  public init() {
    let process = ProceduringProcess(
      executableURL: URL(fileURLWithPath: "/bin/zsh"),
      arguments: ["-c", "nvim --embed"]
    )
    self.stream = .init { continuation in
      Task {
        for try await messageNotification in process {
          guard let notification = ClientNotification(messageNotification: messageNotification) else {
            continue
          }

          continuation.yield(notification)
        }

        continuation.finish()
      }
    }
    self.request = process.request
  }

  public typealias AsyncIterator = AsyncThrowingStream<Element, Error>.AsyncIterator
  public typealias Element = ClientNotification

  public func makeAsyncIterator() -> AsyncIterator {
    self.stream.makeAsyncIterator()
  }

  let request: (_ method: String, _ parameters: [MessagePackValue]) async throws -> MessagePackValue

  private let stream: AsyncThrowingStream<ClientNotification, Error>
}
