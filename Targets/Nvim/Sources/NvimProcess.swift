//
//  NvimProcess.swift
//  Nvim
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import Library
import RxCocoa
import RxSwift

public class NvimProcess {
  @MainActor
  public init(input: Observable<KeyPress>) {
    self.process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
    self.process.executableURL = Bundle.main.url(forResource: "nvim", withExtension: nil)
    self.process.arguments = ["--embed"]

    if let runtimeUrl = Bundle.main.url(forResource: "runtime", withExtension: nil) {
      let environment = ["VIMRUNTIME": runtimeUrl.relativePath]
      log(.info, "Nvim process environment: \(environment)")
      self.process.environment = environment

    } else {
      "Unable to locate nvim runtime"
        .fail()
        .assertionFailure()
    }

    let outputPipe = Pipe()
    self.process.standardOutput = outputPipe

    let outputMessages = outputPipe.fileHandleForReading.data
      .unpack()
      .flatMap { Observable.from($0) }
      .map { try Message(value: $0) }

    let rpc = RPC(inputMessages: outputMessages)
    self.rpc = rpc

    let inputPipe = Pipe()
    self.process.standardInput = inputPipe

    let disposable = rpc.outputMessages
      .map { $0.value.data }
      .subscribe(onNext: { data in
        do {
          try inputPipe.fileHandleForWriting.write(contentsOf: data)

        } catch {
          "Failed writing to process standard input"
            .fail(child: error.fail())
            .fatalError()
        }
      })

    self.process.terminationHandler = { process in
      disposable.dispose()

      "Nvim process terminated with status \(process.terminationStatus), reason \(process.terminationReason)"
        .fail()
        .log(.info)
    }

    self.process <~ input
      .map { $0.makeNvimKeyCode() }
      .bind(with: self) { nvimProcess, keyCode in
        Task {
          do {
            log(.debug, "nvim input: \(keyCode)")

            _ = try await nvimProcess.nvimInput(keys: keyCode)

          } catch {
            "Failed nvim input"
              .fail(child: error.fail())
              .assertionFailure()
          }
        }
      }
  }

  public var notifications: Observable<NvimNotification> {
    self.rpc.notifications
      .flatMap { notification in
        do {
          return Observable.just(try NvimNotification(notification: notification))

        } catch {
          "Failed parsing nvim notification"
            .fail(child: error.fail())
            .assertionFailure()

          return .empty()
        }
      }
      .observe(on: MainScheduler.instance)
      .share(replay: 1, scope: .forever)
  }

  public func run() throws {
    try self.process.run()
  }

  let rpc: RPC

  private let process = Process()
}
