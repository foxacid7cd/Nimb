
import Cocoa
import NvimServiceAPI
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
    
    let errorHandler: (Error) -> Void = { error in
      os_log("NvimService remote object proxy error: \(error)")
    }
    let nvimService = connection.remoteObjectProxyWithErrorHandler(errorHandler) as! NvimServiceProtocol
    self.nvimService = nvimService
    
    startNvim(nvimService: nvimService)
  }
  
  private func startNvim(nvimService: NvimServiceProtocol) {
    let temporaryFileName = "\(UUID().uuidString).nvim"
    let localSocketURL = FileManager.default.temporaryDirectory
      .appending(component: temporaryFileName, directoryHint: .notDirectory)
    
    let arguments = ["--listen", localSocketURL.relativePath]
    
    os_log("Starting nvim with arguments: \(arguments)")
    
    nvimService.startNvim(arguments: arguments) {
      os_log("Started nvim")
      
      DispatchQueue.main.async {
        let callbackTypes: UInt = [
          CFSocketCallBackType.dataCallBack,
          CFSocketCallBackType.connectCallBack
        ]
          .map { $0.rawValue }
          .reduce(0, |)
        
        let socketCallback: CFSocketCallBack = { socket, type, data, _, _ in
          switch type {
          case .connectCallBack:
            os_log("Socket connect callback")
            
          case .dataCallBack:
            os_log("socketCallback data \(CFDataGetLength(data))")
            
          default:
            os_log("Socket unknown callback")
          }
        }
        
        let socket = CFSocketCreate(
          nil,
          PF_LOCAL,
          SOCK_STREAM,
          0,
          callbackTypes,
          socketCallback,
          nil
        )!
        
        let runLoopSource = CFSocketCreateRunLoopSource(nil, socket, 0)!
        CFRunLoopAddSource(
          RunLoop.main.getCFRunLoop(),
          runLoopSource,
          .defaultMode
        )
        
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        
        withUnsafeMutablePointer(to: &address.sun_path.0) { pointer in
          localSocketURL.relativePath
            .utf8CString
            .withUnsafeBytes {
              let pathPointer = $0
                .assumingMemoryBound(to: CChar.self)
                .baseAddress!
              
              let pathLength = strlen(pathPointer)
              address.sun_len = UInt8(pathLength)
              
              strncpy(
                pointer,
                pathPointer,
                pathLength
              )
            }
        }
        
        let result = withUnsafeBytes(of: &address) { bufferPointer in
          let data = CFDataCreate(
            nil,
            bufferPointer
              .assumingMemoryBound(to: UInt8.self)
              .baseAddress,
            bufferPointer.count
          )
          
          return CFSocketConnectToAddress(socket, data, 0)
        }
        
        switch result {
        case .success:
          os_log("Socket connection success")
          
        case .error:
          os_log("Socket connection error")
          
        case .timeout:
          os_log("Socket connection timeout")
          
        default:
          os_log("Socket connection unknown")
        }
      }
    }
  }

  private var connection: NSXPCConnection?
  private var nvimService: NvimServiceProtocol?
}
