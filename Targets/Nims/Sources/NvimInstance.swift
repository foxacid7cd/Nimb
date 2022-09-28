//
//  NvimInstance.swift
//
//
//  Created by Yevhenii Matviienko on 27.09.2022.
//

import Foundation
import Combine
import Procedures
import MessagePack

@MainActor
class NvimInstance {
  var events: AsyncThrowingPublisher<some Publisher> {
    procedureExecutor.events
  }
  
  private let process: Process
  private let procedureExecutor: ProcedureExecutor
  
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
    
    self.procedureExecutor = .init(
      messageEmitter: outputPipe.fileHandleForReading,
      messageConsumer: inputPipe.fileHandleForWriting
    )

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
  
  func execute(procedure: Procedure) async throws -> ExecutionResult {
    try await procedureExecutor.execute(procedure: procedure)
  }
}
