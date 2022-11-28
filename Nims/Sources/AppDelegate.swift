
import AppKit
import Nims_NvimServiceAPI
import OSLog

private let ServiceBundleIdentifier = "foxacid7cd.Nims.NvimService"

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    let connection = NSXPCConnection(serviceName: ServiceBundleIdentifier)
    self.connection = connection
    
    connection.invalidationHandler = { [unowned self] in
      os_log("XPC connection invalidated")
      self.connection = nil
    }

    connection.interruptionHandler = { [unowned self] in
      os_log("XPC connection interrupted")
      self.connection = nil
    }

    connection.remoteObjectInterface = NSXPCInterface(with: NvimServiceProtocol.self)

    connection.activate()

    nvimService = connection.remoteObjectProxyWithErrorHandler { error in
      os_log("NvimService remote object proxy error: \(error)")
    } as? NvimServiceProtocol

    if let nvimService {
      let temporaryFileName = "\(UUID().uuidString).nvim"
      let temporaryFileURL = FileManager.default.temporaryDirectory
        .appending(component: temporaryFileName, directoryHint: .notDirectory)
      
      let arguments = ["--listen", temporaryFileURL.relativePath]

      os_log("Starting nvim with arguments: \(arguments)")

      nvimService.startNvim(arguments: arguments) {
        os_log("Started nvim")
      }
    }
  }

  private var connection: NSXPCConnection?
  private var nvimService: NvimServiceProtocol?
}
