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
    let nvimRuntimeURL = Bundle.main.url(forResource: "runtime", withExtension: nil)!
    environment["VIMRUNTIME"] = nvimRuntimeURL.relativePath
    process.environment = environment
    
    process.terminationHandler = { process in
      os_log("Process terminated: \(process.terminationStatus) \(process.terminationReason.rawValue)")
    }
    
    let standardInputPipe = Pipe()
    process.standardInput = standardInputPipe
    
    let standardOutputPipe = Pipe()
    process.standardOutput = standardOutputPipe
    
    let packer = MessagePacker()
    
    let messageRPC = MessageRPC(
      send: { value in
        Task.detached(priority: .high) {
          let data = await packer.pack(value: value)
          
          try! standardInputPipe.fileHandleForWriting
            .write(contentsOf: data)
        }
      },
      handleNotification: { notification in
        os_log("Notification received: \(notification.method) \(notification.parameters)")
      }
    )
    self.messageRPC = messageRPC
    
    let unpacker = MessageUnpacker()
    
    standardOutputPipe.fileHandleForReading
      .readabilityHandler = { fileHandle in
        let data = fileHandle.availableData
        
        Task { @MainActor in
          do {
            let values = try unpacker.unpack(data: data)
            for value in values {
              try messageRPC.handleReceived(value: value)
            }
            
          } catch {
            fatalError("Unpacker failed unpacking or MessageRPC failed receiving: \(error)")
          }
        }
      }
    
    try! process.run()
    
    os_log("Process started!")
    
    Task {
      try! await messageRPC.request(method: "nvim_ui_attach", parameters: [
        MessageUInt32Value(80),
        MessageUInt32Value(24),
        MessageMapValue([
          (MessageStringValue("rgb"), MessageBooleanValue(true)),
          (MessageStringValue("override"), MessageBooleanValue(true)),
          (MessageStringValue("ext_multigrid"), MessageBooleanValue(true))
        ])
      ])
    }
  }
  
  private var process: Process?
  private var messageRPC: MessageRPC?
}
