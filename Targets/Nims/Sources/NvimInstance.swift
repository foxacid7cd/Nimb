//
//  NvimInstance.swift
//
//
//  Created by Yevhenii Matviienko on 27.09.2022.
//

import API
import Combine
import Foundation
import MessagePack
import Procedures

@MainActor
class NvimInstance {
  var events: AsyncThrowingPublisher<some Publisher> {
    procedureExecutor.events
  }

  private let process: Process
  private let procedureExecutor: ProcedureExecutor

  let client: Client

  init(executableURL: URL) throws {
    let process = Process()
    self.process = process
    process.executableURL = executableURL
    process.arguments = ["--embed"]
    process.terminationHandler = { process in
      log(.info, "nvim process terminated for reason \(process.terminationReason), exit code \(process.terminationStatus)")
    }

    let inputPipe = Pipe()
    process.standardInput = inputPipe

    let outputPipe = Pipe()
    process.standardOutput = outputPipe

    let procedureExecutor = ProcedureExecutor(
      messageEmitter: outputPipe.fileHandleForReading,
      messageConsumer: inputPipe.fileHandleForWriting
    )
    self.procedureExecutor = procedureExecutor
    self.client = Client(procedureExecutor: procedureExecutor)

    let errorPipe = Pipe()
    process.standardError = errorPipe

    errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
      let data = fileHandle.availableData
      guard !data.isEmpty else {
        errorPipe.fileHandleForReading.readabilityHandler = nil
        log(.info, "nvim stderr end of stream.")
        return
      }
      if let string = String(data: data, encoding: .utf8) {
        log(.error, "nvim stderr: \(string).")
      }
    }

    try process.run()
    log(.info, "Started nvim.")
  }
}
