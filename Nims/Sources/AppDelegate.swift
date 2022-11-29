//
//  AppDeletate.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Cocoa
import MessagePack
import NvimServiceAPI
import OSLog

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  @MainActor
  func applicationDidFinishLaunching(_ notification: Notification) {
    let nimsUI = NimsUI { [unowned self] event in
      Task {
        let keyPress = KeyPress(event: event)
        do {
          try await self.messageRPC?.request(
            method: "nvim_input",
            parameters: [keyPress.makeNvimKeyCode()]
          )

        } catch {
          os_log("nvim_input failed: \(error)")
        }
      }
    }
    self.nimsUI = nimsUI

    nimsUI.start()

    let process = Process()
    self.process = process

    let executableURL = Bundle.main.url(forAuxiliaryExecutable: "nvim")!
    process.executableURL = executableURL
    process.arguments = [executableURL.relativePath, "--embed"]

    var environment = ProcessInfo.processInfo.environment
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
      sendMessageValue: { value in
        Task { @MainActor in
          let data = packer.pack(messageValue: value)

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
              let parameterArrayValue = parameter as? [MessageValue],
              let uiEventName = parameterArrayValue.first as? String
            else {
              os_log("Unexpected redraw notification structure")
              continue
            }

            guard let name = RedrawUIEventName(rawValue: uiEventName) else {
              os_log("Unexpected redraw UI event with name: \(uiEventName)")
              continue
            }

            func forEachParametersTuple(_ body: (inout [MessageValue]) throws -> Void) {
              for i in 1 ..< parameterArrayValue.count {
                do {
                  guard var parameters = parameterArrayValue[i] as? [MessageValue] else {
                    throw RedrawNotificationParsingError.uiEventParametersIsNotArray
                  }

                  try body(&parameters)

                } catch {
                  os_log("Redraw notification parsing failed: \(error)")
                }
              }
            }

            switch name {
            case .gridResize:
              forEachParametersTuple { parameters in
                var parameters = parameters

                guard
                  parameters.count == 3,
                  let gridID = parameters.removeFirst() as? Int,
                  let width = parameters.removeFirst() as? Int,
                  let height = parameters.removeFirst() as? Int
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                nimsUI.gridResize(
                  gridID: gridID,
                  gridSize: .init(
                    width: width,
                    height: height
                  )
                )
              }

            case .gridLine:
              var lastHlID: Int?
              var lastY: Int?

              forEachParametersTuple { parameters in
                guard
                  parameters.count == 4,
                  let gridID = parameters.removeFirst() as? Int,
                  let y = parameters.removeFirst() as? Int,
                  let x = parameters.removeFirst() as? Int,
                  let data = parameters.removeFirst() as? [MessageValue]
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                let origin = GridPoint(x: x, y: y)

                var updatedCellsCount = 0
                var updatedCells = [Cell]()

                for value in data {
                  guard var arrayValue = value as? [MessageValue] else {
                    throw RedrawNotificationParsingError.gridLineCellDataIsNotArray
                  }

                  guard !arrayValue.isEmpty, let text = arrayValue.removeFirst() as? String else {
                    throw RedrawNotificationParsingError.gridLineCellTextIsNotString
                  }
                  if text.count > 1 {
                    throw RedrawNotificationParsingError.gridLineCellTextIsNotString
                  }
                  let character = text.first

                  var repeatCount = 1

                  if !arrayValue.isEmpty {
                    guard let hlID = arrayValue.removeFirst() as? Int else {
                      throw RedrawNotificationParsingError.gridLineHlIDIsNotInt
                    }
                    lastHlID = hlID

                    if !arrayValue.isEmpty {
                      guard let parsedRepeatCount = arrayValue.removeFirst() as? Int else {
                        throw RedrawNotificationParsingError.gridLineCellRepeatCountIsNotInt
                      }
                      repeatCount = parsedRepeatCount
                    }
                  }

                  guard let lastHlID else {
                    throw RedrawNotificationParsingError.gridLineHlIDNotParsedYet
                  }

                  if lastY != y {
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

                  lastY = y
                }

                nimsUI.gridLine(gridID: gridID, origin: origin, cells: updatedCells)
              }

            case .gridClear:
              forEachParametersTuple { parameters in
                guard
                  parameters.count == 1,
                  let gridID = parameters.removeFirst() as? Int
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                nimsUI.gridClear(gridID: gridID)
              }

            case .gridCursorGoto:
              os_log("gridCursorGoto!")

            case .winPos:
              forEachParametersTuple { parameters in
                guard
                  parameters.count == 6,
                  let gridID = parameters.removeFirst() as? Int,
                  let winRef = parameters.removeFirst() as? (data: Data, type: Int8),
                  let y = parameters.removeFirst() as? Int,
                  let x = parameters.removeFirst() as? Int,
                  let width = parameters.removeFirst() as? Int,
                  let height = parameters.removeFirst() as? Int
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                nimsUI.winPos(
                  gridID: gridID,
                  winRef: WinRef(data: winRef.data),
                  winFrame: .init(
                    origin: .init(
                      x: x,
                      y: y
                    ),
                    size: .init(
                      width: width,
                      height: height
                    )
                  )
                )
              }

            case .defaultColorsSet:
              forEachParametersTuple { parameters in
                guard
                  parameters.count == 5,
                  let rgbFg = parameters.removeFirst() as? Int,
                  let rgbBg = parameters.removeFirst() as? Int,
                  let rgbSp = parameters.removeFirst() as? Int,
                  let _ = parameters.removeFirst() as? Int,
                  let _ = parameters.removeFirst() as? Int
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                nimsUI.defaultColorsSet(
                  rgbFg: rgbFg,
                  rgbBg: rgbBg,
                  rgbSp: rgbSp
                )
              }

            case .hlAttrDefine:
              forEachParametersTuple { parameters in
                guard
                  parameters.count == 4,
                  let id = parameters.removeFirst() as? Int,
                  let rgbAttr = parameters.removeFirst() as? [(key: String, value: MessageValue)],
                  let _ = parameters.removeFirst() as? [(key: String, value: MessageValue)],
                  let _ = parameters.removeFirst() as? [MessageValue]
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                nimsUI.hlAttrDefine(id: id, rgbAttr: rgbAttr)
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
            try unpacker.unpack(data: data)
              .forEach { try messageRPC.handleReceived(value: $0) }

          } catch {
            fatalError("Unpacker failed unpacking or MessageRPC failed receiving: \(error)")
          }
        }
      }

    try! process.run()

    os_log("Process started!")

    Task {
      do {
        let options = [("rgb", true), ("override", true), ("ext_multigrid", true)]
        try await messageRPC.request(method: "nvim_ui_attach", parameters: [120, 40, options])

      } catch {
        os_log("nvim_ui_attach failed: \(error)")
      }
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
  case gridLineHlIDIsNotInt
  case gridLineCellRepeatCountIsNotInt
  case gridLineHlIDNotParsedYet
}
