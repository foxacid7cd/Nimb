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
  func applicationDidFinishLaunching(_ notification: Notification) {
    let connection = NSXPCConnection(serviceName: "\(Bundle.main.bundleIdentifier!).NvimService")
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
    
    let localSocketURL = URL(fileURLWithPath: "/tmp", isDirectory: true)
      .appendingPathComponent(temporaryFileName, isDirectory: false)
    
    let arguments = ["--listen", localSocketURL.relativePath]
    
    os_log("Starting nvim with arguments: \(arguments)")
    
    nvimService.startNvim(arguments: arguments) {
      let socketThread = Thread {
        os_log("Started nvim")
        
        let callbackTypes: UInt = [
          CFSocketCallBackType.dataCallBack,
          CFSocketCallBackType.writeCallBack,
          CFSocketCallBackType.connectCallBack
        ]
          .map { $0.rawValue }
          .reduce(0, |)
        
        let socketCallback: CFSocketCallBack = { socket, type, cfData, _, _ in
          switch type {
          case .connectCallBack:
            os_log("Socket connect callback")
            
          case .dataCallBack:
            let data = cfData! as Data
            message_unpack(data: data)
            
          case .writeCallBack:
            os_log("Socket write callback")
            
            let data = message_pack()
            CFSocketSendData(socket, nil, data as CFData, 0)
            
            os_log("Sent \(data.count) bytes to socket")
            
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
        self.socket = socket
        
        let runLoopSource = CFSocketCreateRunLoopSource(nil, socket, 0)!
        CFRunLoopAddSource(
          RunLoop.current.getCFRunLoop(),
          runLoopSource,
          .defaultMode
        )
        
        RunLoop.current.schedule {
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
                address.sun_len = UInt8(pathLength) + 1
                
                strncpy(
                  pointer,
                  pathPointer,
                  pathLength
                )
              }
          }
          
          let data = withUnsafeBytes(of: &address) { bufferPointer in
            return Data(bytes: bufferPointer.baseAddress!, count: bufferPointer.count)
          }
          let cfData = data as CFData
          
          let result = CFSocketConnectToAddress(socket, cfData, 0)
          
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
        
        self.socketRunLoop = RunLoop.current
        RunLoop.current.run()
      }
      self.socketThread = socketThread
      
      socketThread.name = "\(Bundle.main.bundleIdentifier!).CFSocketThread"
      socketThread.start()
    }
  }
  
  private var connection: NSXPCConnection?
  private var nvimService: NvimServiceProtocol?
  private var socketThread: Thread?
  private var socketRunLoop: RunLoop?
  private var socket: CFSocket?
}
