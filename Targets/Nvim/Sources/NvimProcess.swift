//
//  NvimProcess.swift
//  Nvim
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import Library
import RxSwift

public class NvimProcess {
  private let process = Process()
  
  @MainActor
  public init() {
    process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
    process.executableURL = .init(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", "nvim --embed"]

    let outputPipe = Pipe()
    process.standardOutput = outputPipe

    let outputMessages = outputPipe.fileHandleForReading.data
      .unpack()
      .flatMap { Observable.from($0) }
      .map { try Message(value: $0) }

    let rpc = RPC(inputMessages: outputMessages)
    self.rpc = rpc

    let inputPipe = Pipe()
    process.standardInput = inputPipe

    let disposable = rpc.outputMessages
      .map { $0.value.data }
      .subscribe(onNext: { data in
        do {
          try inputPipe.fileHandleForWriting.write(contentsOf: data)
        } catch {
          "failed writing to process standard input"
            .fail(child: error.fail())
            .fatal()
        }
      })

    process.terminationHandler = { process in
      disposable.dispose()

      "nvim process terminated with status \(process.terminationStatus), reason \(process.terminationReason)"
        .fail()
        .log(.info)
    }

    do {
      try process.run()
    } catch {
      "failed running nvim process"
        .fail(child: error.fail())
        .fatal()
    }
  }

  public var notifications: Observable<NvimNotification> {
    self.rpc.notifications
      .map { notification in
        do {
          return try .init(notification: notification)

        } catch {
          "failed parsing nvim notification"
            .fail(child: error.fail())
            .fatal()
        }
      }
  }
  
  public func run() throws {
    try process.run()
  }

  let rpc: RPC
}
