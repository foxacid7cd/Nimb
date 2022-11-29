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

  private var mainThread: Thread?
}

class ListenerDelegate: NSObject, NSXPCListenerDelegate {
  init(nvimService: NvimService) {
    self.nvimService = nvimService
  }

  func listener(_: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
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
    newConnection.exportedObject = self.nvimService

    newConnection.activate()
    connection = newConnection

    return true
  }

  private let nvimService: NvimService

  private var connection: NSXPCConnection?
}

let nvimService = NvimService()

let listenerDelegate = ListenerDelegate(nvimService: nvimService)

let listener = NSXPCListener.service()
listener.delegate = listenerDelegate

listener.activate()
