//
//  main.swift
//  _idx_NvimServiceLib_66005C7B_ios_min16.1
//
//  Created by Yevhenii Matviienko on 22.11.2022.
//

import Foundation
import Nims_NvimServiceAPI
import OSLog

class NvimService: NvimServiceProtocol {
  func startNvim(arguments: [String], _ callback: @escaping () -> Void) {
    os_log("Starting nvim with arguments: \(arguments)")

    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
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
