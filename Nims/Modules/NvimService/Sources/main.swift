//
//  main.swift
//  _idx_NvimServiceLib_66005C7B_ios_min16.1
//
//  Created by Yevhenii Matviienko on 22.11.2022.
//

import Foundation
import NvimServiceAPI
import OSLog

class NvimService: NvimServiceProtocol {
  private var mainThread: Thread?
  
  func startNvim(arguments: [String], _ callback: @escaping () -> Void) {
    guard mainThread == nil else {
      os_log("Failed starting nvim, already started")
      callback()
      
      return
    }
    
    os_log("Starting nvim with arguments: \(arguments)")
    
    let mainThread = Thread {
      var cArguments = ([ProcessInfo.processInfo.arguments[0]] + arguments)
        .map { UnsafeMutablePointer<Int8>(strdup($0)) }
      
      nvim_main(Int32(cArguments.count), &cArguments)
      os_log("nvim_main ended")
      
      cArguments.forEach { free($0) }
    }
    self.mainThread = mainThread
    
    mainThread.name = "\(Bundle.main.bundleIdentifier!).nvim_main"
    mainThread.start()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
      os_log("Started nvim")

      callback()
    }
  }
}

class ListenerDelegate: NSObject, NSXPCListenerDelegate {
  private let nvimService: NvimService

  init(nvimService: NvimService) {
    self.nvimService = nvimService
  }

  private var connection: NSXPCConnection?

  func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
    if let connection {
      connection.invalidate()
    }

    newConnection.invalidationHandler = { [unowned self] in
      os_log("XPC connection invalidated")
      self.connection = nil
    }

    newConnection.interruptionHandler = { [unowned self] in
      os_log("XPC connection interrupted")
      self.connection = nil
    }

    newConnection.exportedInterface = NSXPCInterface(with: NvimServiceProtocol.self)
    newConnection.exportedObject = nvimService

    newConnection.activate()
    connection = newConnection

    return true
  }
}

let nvimService = NvimService()

let listenerDelegate = ListenerDelegate(nvimService: nvimService)

let listener = NSXPCListener.service()
listener.delegate = listenerDelegate

listener.activate()
