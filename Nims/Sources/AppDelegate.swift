//
//  AppDeletate.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Cocoa
import NvimServiceAPI
import OSLog
import MessagePack

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  @MainActor
  func applicationDidFinishLaunching(_ notification: Notification) {
    let process = Process()
    self.process = process
    
    let executableURL = Bundle.main.url(forAuxiliaryExecutable: "nvim")!
    process.executableURL = executableURL
    process.arguments = [executableURL.relativePath, "--embed"]
    
    var environment = ProcessInfo.processInfo.environment
    environment["VIMRUNTIME"] = "/opt/homebrew/share/nvim/runtime"
    process.environment = environment
    
    process.terminationHandler = { process in
      os_log("Process terminated: \(process.terminationStatus) \(process.terminationReason.rawValue)")
    }
    
    let standardOutputPipe = Pipe()
    process.standardOutput = standardOutputPipe
    
    standardOutputPipe.fileHandleForReading
      .readabilityHandler = { fileHandle in
        let data = fileHandle.availableData
        
        Task.detached(priority: .high) {
          await message_unpack(data: data)
        }
      }
    
    let standardInputPipe = Pipe()
    process.standardInput = standardInputPipe
    
    try! process.run()
    
    os_log("Process started!")
    
    Task.detached(priority: .high) {
      let request = RPCRequest(
        id: 0,
        method: "nvim_ui_attach",
        parameters: [
          MessageUInt32Value(80),
          MessageUInt32Value(24),
          MessageMapValue([
            (MessageStringValue("rgb"), MessageBooleanValue(true)),
            (MessageStringValue("override"), MessageBooleanValue(true)),
            (MessageStringValue("ext_multigrid"), MessageBooleanValue(true))
          ])
        ]
      )
      let packer = MessagePacker()
      
      let data = packer.pack(value: request)
      
      try! standardInputPipe.fileHandleForWriting
        .write(contentsOf: data)
    }
  }
  
  private var process: Process?
}
