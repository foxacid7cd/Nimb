// SPDX-License-Identifier: MIT

import ArgumentParser
import CoreLocation
import Darwin
import Foundation
import System

var orig_termios = termios()

struct CollectMsgpackData: AsyncParsableCommand {
  @Argument
  public var nvimExecutablePath: String

  @Option(name: .shortAndLong, completion: .file())
  public var output: String? = nil

  @Argument(parsing: .allUnrecognized)
  public var nvimArguments: [String] = []

  static let configuration = CommandConfiguration(
    commandName: "collect-msgpack-data",
    shouldDisplay: true,
    subcommands: [],
    groupedSubcommands: []
  )

  func run() async throws {
    var fd: FileDescriptor?
    if let output {
      fd = try FileDescriptor.open(.init(output), .readWrite, options: .closeOnExec)
    }

    var fdMaster: Int32 = 0
    var fdSlave: Int32 = 0
    let rc = openpty(&fdMaster, &fdSlave, nil, nil, nil)
    if rc != 0 {
      throw Errno(rawValue: rc)
    }
    _ = fcntl(fdMaster, F_SETFD, FD_CLOEXEC)
    _ = fcntl(fdSlave, F_SETFD, FD_CLOEXEC)
    _ = FileHandle(fileDescriptor: fdMaster, closeOnDealloc: true)
    let slaveHandle = FileHandle(fileDescriptor: fdSlave, closeOnDealloc: true)

    let process = Process()
    process.environment = ProcessInfo.processInfo.environment
    process.executableURL = URL(filePath: nvimExecutablePath)
    process.arguments = nvimArguments
    process.standardInput = slaveHandle
    process.standardOutput = slaveHandle

    try process.run()

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

//    fflush(stdout)
//    set_conio_terminal_mode()
//
//    Task.detached {
//      for update in (Updates ... pdates.length) {
//
//      }
//    }

    if let fd {
      _ = try fd.duplicate()
    }

    reset_terminal_mode()
  }
}
