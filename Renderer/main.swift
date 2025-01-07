// SPDX-License-Identifier: MIT

import AppKit

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
  func listener(
    _ listener: NSXPCListener,
    shouldAcceptNewConnection newConnection: NSXPCConnection
  )
  -> Bool {
    let exportedInterface = NSXPCInterface(with: RendererProtocol.self)
    newConnection.exportedInterface = exportedInterface

    let renderer = Renderer()
    newConnection.exportedObject = renderer

    newConnection.resume()

    return true
  }
}

let delegate = ServiceDelegate()

let listener = NSXPCListener.service()
listener.delegate = delegate

listener.activate()
