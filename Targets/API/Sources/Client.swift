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
  public typealias AsyncIterator = AsyncStream<Element>.AsyncIterator
  public typealias Element = ClientNotification

  private let stream: AsyncStream<ClientNotification>

  let request: (_ method: String, _ parameters: [MessagePackValue]) async throws -> MessagePackValue

  @MainActor
  public init() {
    let process = ProceduringProcess(
      executableURL: URL(fileURLWithPath: "/bin/zsh"),
      arguments: ["-c", "nvim --embed"]
    )
    stream = .init { continuation in
      Task {
        for await messageNotification in process {
          guard let notification = ClientNotification(messageNotification: messageNotification) else {
            continue
          }

          continuation.yield(notification)
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
