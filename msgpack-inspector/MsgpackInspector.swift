// SPDX-License-Identifier: MIT

import ArgumentParser
import CoreLocation
import Darwin
import Foundation
import System

@main
struct MsgpackInspector: AsyncParsableCommand {
  @Option(name: .shortAndLong, completion: .file())
  public var output: String? = nil

  @Argument
  public var executablePath: String

  @Argument(parsing: .captureForPassthrough)
  public var passthroughArguments: [String] = []

  func run() async throws {
    var fdMaster: Int32 = 0
    var fdSlave: Int32 = 0
    let rc = openpty(&fdMaster, &fdSlave, nil, &orig_termios, nil)
    if rc != 0 {
      throw Errno(rawValue: rc)
    }
    _ = fcntl(fdMaster, F_SETFD, FD_CLOEXEC)
    _ = fcntl(fdSlave, F_SETFD, FD_CLOEXEC)
    let masterHandle = FileHandle(fileDescriptor: fdMaster, closeOnDealloc: true)
    let slaveHandle = FileHandle(fileDescriptor: fdSlave, closeOnDealloc: true)

    let process = Process()
    process.environment = ProcessInfo.processInfo.environment
    process.executableURL = URL(filePath: executablePath)
    process.arguments = passthroughArguments
    process.standardInput = slaveHandle
    process.standardOutput = slaveHandle

    set_conio_terminal_mode()
    defer { reset_terminal_mode() }

    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        for await dataBatch in FileHandle.standardInput.dataBatches {
          try Task.checkCancellation()
          try masterHandle.write(contentsOf: dataBatch)
        }
      }
      group.addTask {
        var outputFileHandle: FileHandle?
        if let output {
          if !FileManager.default.fileExists(atPath: output) {
            FileManager.default.createFile(atPath: output, contents: nil, attributes: nil)
          }
          outputFileHandle = FileHandle(forWritingAtPath: output)
        }
        defer {
          try? outputFileHandle?.synchronize()
          try? outputFileHandle?.close()
        }
        for await dataBatch in masterHandle.dataBatches {
          try Task.checkCancellation()
          try FileHandle.standardOutput.write(contentsOf: dataBatch)
          try outputFileHandle?.write(contentsOf: dataBatch)
        }
      }
      group.addTask {
        try process.run()
        process.waitUntilExit()
      }
      defer { group.cancelAll() }
      do {
        for try await () in group {
          return
        }
      } catch is CancellationError {
      } catch {
        throw error
      }
    }
  }
}

var orig_termios = termios()
func reset_terminal_mode() {
  tcsetattr(0, TCSANOW, &orig_termios)
}

func set_conio_terminal_mode() {
  tcgetattr(0, &orig_termios)
  var new_termios = orig_termios
  atexit(reset_terminal_mode)
  cfmakeraw(&new_termios)
  tcsetattr(0, TCSANOW, &new_termios)
}
