//
//  SpeedTuner.swift
//  speed-tuner
//
//  Created by Yevhenii Matviienko on 03.08.2024.
//

import ArgumentParser
import Foundation
import Library
import System
import Darwin

var orig_termios = termios()

struct CollectMsgpackData: AsyncParsableCommand {
  static let configuration = CommandConfiguration(commandName: "collect-msgpack-data", shouldDisplay: true, subcommands: [], groupedSubcommands: [])
  
  @Option(name: .shortAndLong, completion: .file())
  public var output: String
  
  @Argument
  public var nvimExecutablePath: String
  
  @Argument(parsing: .remaining)
  public var nvimArguments: [String]
  
  func run() async throws {
    let outputFileDescriptor = try FileDescriptor.open(.init(output), .writeOnly, options: [.closeOnExec, .create, .truncate])
    
    var fdMaster: Int32 = 0;
    var fdSlave: Int32 = 0;
    let rc = openpty(&fdMaster, &fdSlave, nil, nil, nil)
    if (rc != 0) {
      throw Errno(rawValue: rc)
    }
    _ = fcntl(fdMaster, F_SETFD, FD_CLOEXEC);
    _ = fcntl(fdSlave, F_SETFD, FD_CLOEXEC);
    let masterHandle = FileHandle(fileDescriptor: fdMaster, closeOnDealloc: true)
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
    
    fflush(stdout)
    set_conio_terminal_mode()
    
    Task.detached {
      for try await data in masterHandle.dataBatches {
        try FileHandle.standardOutput.write(contentsOf: data)
        
        try outputFileDescriptor.writeAll(data)
      }
    }
    Task.detached {
      for try await data in FileHandle.standardInput.dataBatches {
        try masterHandle.write(contentsOf: data)
      }
    }
    
    process.waitUntilExit()
    
    print("\r")
    reset_terminal_mode()
  }
}
