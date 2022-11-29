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
            
            func forEachUIEventParametersTuple(_ body: ([MessageValue]) throws -> Void) {
              for i in (1..<parameterArrayValue.elements.count) {
                do {
                  guard let uiEventParameters = parameterArrayValue.elements[i] as? MessageArrayValue else {
                    throw RedrawNotificationParsingError.uiEventParametersIsNotArray
                  }
                  
                  try body(uiEventParameters.elements)
                  
                } catch {
                  os_log("Redraw notification parsing failed: \(error)")
                }
              }
            }
            
            switch name {
            case .gridResize:
              forEachUIEventParametersTuple { parameters in
                var parameters = parameters
                
                guard
                  parameters.count == 3,
                  let gridID = parameters.removeFirst() as? MessageIntValue,
                  let width = parameters.removeFirst() as? MessageIntValue,
                  let height = parameters.removeFirst() as? MessageIntValue
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }
                
                nimsUI.gridResize(
                  gridID: gridID.value,
                  gridSize: .init(
                    width: width.value,
                    height: height.value
                  )
                )
              }
              
            case .gridLine:
              var lastHlID: Int?
              var lastY: Int?
              
              forEachUIEventParametersTuple { parameters in
                var parameters = parameters
                
                guard
                  parameters.count == 4,
                  let gridID = parameters.removeFirst() as? MessageIntValue,
                  let y = parameters.removeFirst() as? MessageIntValue,
                  let x = parameters.removeFirst() as? MessageIntValue,
                  let data = parameters.removeFirst() as? MessageArrayValue
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }
                
                let origin = GridPoint(
                  x: x.value,
                  y: y.value
                )
                
                var updatedCellsCount = 0
                var updatedCells = [Cell]()

                for value in data.elements {
                  guard let arrayValue = value as? MessageArrayValue else {
                    throw RedrawNotificationParsingError.gridLineCellDataIsNotArray
                  }
                  var elements = arrayValue.elements

                  guard !elements.isEmpty, let stringValue = elements.removeFirst() as? MessageStringValue else {
                    throw RedrawNotificationParsingError.gridLineCellTextIsNotString
                  }
                  let text = stringValue.string
                  if text.count > 1 {
                    throw RedrawNotificationParsingError.gridLineCellTextIsNotString
                  }
                  let character = text.first

                  var repeatCount = 1

                  if !elements.isEmpty {
                    guard let hlID = elements.removeFirst() as? MessageIntValue else {
                      throw RedrawNotificationParsingError.gridLineHlIdIsNotInt
                    }
                    lastHlID = Int(hlID.value)

                    if !elements.isEmpty {
                      guard let parsedRepeatCount = elements.removeFirst() as? MessageIntValue else {
                        throw RedrawNotificationParsingError.gridLineCellRepeatCountIsNotInt
                      }
                      repeatCount = parsedRepeatCount.value
                    }
                  }

                  guard let lastHlID else {
                    throw RedrawNotificationParsingError.gridLineHlIDNotParsedYet
                  }

                  if lastY != y.value {
                    updatedCellsCount = 0
                  }

                  for _ in 0 ..< repeatCount {
                    let cell = Cell(
                      character: character,
                      hlID: lastHlID
                    )
                    updatedCells.append(cell)
                  }

                  updatedCellsCount += repeatCount

                  lastY = y.value
                }
                
                nimsUI.gridLine(gridID: gridID.value, origin: origin, cells: updatedCells)
              }
              
            case .gridClear:
              os_log("gridClear!")
              
            case .gridCursorGoto:
              os_log("gridCursorGoto!")
              
            case .winPos:
              forEachUIEventParametersTuple { parameters in
                var parameters = parameters
                
                guard
                  parameters.count == 6,
                  let gridID = parameters.removeFirst() as? MessageIntValue,
                  let winRef = parameters.removeFirst() as? MessageExtValue,
                  let y = parameters.removeFirst() as? MessageIntValue,
                  let x = parameters.removeFirst() as? MessageIntValue,
                  let width = parameters.removeFirst() as? MessageIntValue,
                  let height = parameters.removeFirst() as? MessageIntValue
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
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
              }
              
            case .flush:
              os_log("FLUSH!")
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

enum RedrawNotificationParsingError: Error {
  case uiEventParametersIsNotArray
  case invalidParameterTypes
  case gridLineCellDataIsNotArray
  case gridLineCellTextIsNotString
  case gridLineHlIdIsNotInt
  case gridLineCellRepeatCountIsNotInt
  case gridLineHlIDNotParsedYet
}
