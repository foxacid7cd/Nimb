// SPDX-License-Identifier: MIT

import Foundation

@MainActor
class ServiceDelegate: NSObject, @preconcurrency NSXPCListenerDelegate {
  /// This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
  func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
    // Configure the connection.
    // First, set the interface that the exported object implements.
    let exportedInterface = NSXPCInterface(with: RendererProtocol.self)
    exportedInterface
      .setXPCType(
        XPC_TYPE_SHMEM,
        for: #selector(
          RendererProtocol.set(sharedMemoryXPC:reply:)
        ),
        argumentIndex: 0,
        ofReply: false
      )
    newConnection.exportedInterface = exportedInterface

    // Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
    let exportedObject = Renderer(initialState: .init(font: .init()))
    newConnection.exportedObject = exportedObject

    // Resuming the connection allows the system to deliver more incoming messages.
    newConnection.resume()

    // Returning true from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call invalidate() on the connection and return
    // false.
    return true
  }
}

/// Create the delegate for the service.
let delegate = ServiceDelegate()

/// Set up the one NSXPCListener for this service. It will handle all incoming connections.
let listener = NSXPCListener.service()
listener.delegate = delegate

// Resuming the serviceListener starts this service. This method does not return.
listener.resume()
