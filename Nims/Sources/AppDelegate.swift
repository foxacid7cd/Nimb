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
    let nimsUI = NimsUI()
    self.nimsUI = nimsUI
    
    nimsUI.start()
    
    let process = Process()
    self.process = process
    
    let executableURL = Bundle.main.url(forAuxiliaryExecutable: "nvim")!
    process.executableURL = executableURL
    process.arguments = [executableURL.relativePath, "--embed"]
    
    var environment = ProcessInfo.processInfo.environment
//    let nvimRuntimeURL = Bundle.main.url(forResource: "runtime", withExtension: nil)!
//    environment["VIMRUNTIME"] = nvimRuntimeURL.relativePath
    environment["VIMRUNTIME"] = "/opt/homebrew/share/nvim/runtime"
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
        Task { @MainActor in
          let data = packer.pack(value: value)
          
          try! standardInputPipe.fileHandleForWriting
            .write(contentsOf: data)
        }
      },
      handleNotification: { notification in
        guard let method = NvimNotificationMethodName(rawValue: notification.method) else {
          os_log("Unexpected nvim notification method: \(notification.method)")
          return
        }
        
        switch method {
        case .redraw:
          for parameter in notification.parameters {
            guard
              let parameterArrayValue = parameter as? MessageArrayValue,
              let uiEventName = parameterArrayValue.elements.first as? MessageStringValue
            else {
              os_log("Unexpected redraw notification structure")
              continue
            }
            
            guard let name = RedrawUIEventName(rawValue: uiEventName.string) else {
              os_log("Unexpected redraw UI event with name: \(uiEventName.string)")
              continue
            }
            
            for i in (1..<parameterArrayValue.elements.count) {
              guard let uiEventParameters = parameterArrayValue.elements[i] as? MessageArrayValue else {
                os_log("Unexpected, uiEventParameters is not an array")
                continue
              }
              
              var elements = uiEventParameters.elements
              
              switch name {
              case .gridResize:
                guard
                  elements.count == 3,
                  let gridID = elements.removeFirst() as? MessageIntValue,
                  let width = elements.removeFirst() as? MessageIntValue,
                  let height = elements.removeFirst() as? MessageIntValue
                else {
                  os_log("Failed parsing gridResize UI event")
                  continue
                }
                
                nimsUI.gridResize(
                  gridID: gridID.value,
                  gridSize: .init(
                    width: width.value,
                    height: height.value
                  )
                )
                
              case .gridLine:
                os_log("gridLine!")
                
              case .gridClear:
                os_log("gridClear!")
                
              case .gridCursorGoto:
                os_log("gridCursorGoto!")
                
              case .winPos:
                guard
                  elements.count == 6,
                  let gridID = elements.removeFirst() as? MessageIntValue,
                  let winRef = elements.removeFirst() as? MessageExtValue,
                  let y = elements.removeFirst() as? MessageIntValue,
                  let x = elements.removeFirst() as? MessageIntValue,
                  let width = elements.removeFirst() as? MessageIntValue,
                  let height = elements.removeFirst() as? MessageIntValue
                else {
                  os_log("Failed parsing winPos UI event")
                  continue
                }
                
                nimsUI.winPos(
                  gridID: gridID.value,
                  winRef: WinRef(data: winRef.data),
                  winFrame: .init(
                    origin: .init(
                      x: x.value,
                      y: y.value
                    ),
                    size: .init(
                      width: width.value,
                      height: height.value
                    )
                  )
                )
                
              case .flush:
                os_log("FLUSH!")
              }
            }
          }
        }
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
        MessageIntValue(80),
        MessageIntValue(24),
        MessageMapValue([
          (MessageStringValue("rgb"), MessageBooleanValue(true)),
          (MessageStringValue("override"), MessageBooleanValue(true)),
          (MessageStringValue("ext_multigrid"), MessageBooleanValue(true))
        ])
      ] as [MessageValue])
    }
  }
  
  private var process: Process?
  private var messageRPC: MessageRPC?
  private var nimsUI: NimsUI?
}
