//
//  NvimInstance.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Cocoa
import MessagePack
import OSLog

@MainActor
class NvimInstance {
  init() {
    let appearance = Appearance()
    self.appearance = appearance

    let window = Window(
      contentRect: .zero,
      styleMask: [.titled],
      backing: .buffered,
      defer: true
    )
    self.window = window

    let mainView = MainView(appearance: appearance)
    window.contentView = mainView

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
      send: { value in
        let data = packer.pack(messageValue: value)

        do {
          try standardInputPipe.fileHandleForWriting
            .write(contentsOf: data)

        } catch {
          os_log("Failed writing to process standard input: \(error)")
        }
      }
    )
    self.messageRPC = messageRPC

    Task {
      for await notification in messageRPC.notifications {
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

            func forEachParametersTuple(_ body: (inout [MessageValue]) async throws -> Void) async {
              for i in 1 ..< parameterArrayValue.count {
                do {
                  guard var parameters = parameterArrayValue[i] as? [MessageValue] else {
                    throw RedrawNotificationParsingError.uiEventParametersIsNotArray
                  }

                  try await body(&parameters)

                } catch {
                  os_log("Redraw notification parsing failed: \(error)")
                }
              }
            }

            switch name {
            case .gridResize:
              await forEachParametersTuple { parameters in
                var parameters = parameters

                guard
                  parameters.count == 3,
                  let gridID = parameters.removeFirst() as? Int,
                  let width = parameters.removeFirst() as? Int,
                  let height = parameters.removeFirst() as? Int
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                if gridID == 1 {
                  let gridSize = GridSize(width: width, height: height)
                  let cellSize = await appearance.cellSize()
                  window.setContentSize(gridSize * cellSize)
                }

                mainView.gridResize(
                  gridID: gridID,
                  gridSize: .init(width: width, height: height)
                )
              }

            case .gridLine:
              var lastHlID: Int?
              var lastY: Int?

              await forEachParametersTuple { parameters in
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
                      text: text,
                      highlightID: lastHlID
                    )
                    updatedCells.append(cell)
                  }

                  updatedCellsCount += repeatCount

                  lastY = y
                }

                mainView.gridLine(gridID: gridID, origin: origin, cells: updatedCells)
              }

            case .gridClear:
              await forEachParametersTuple { parameters in
                guard
                  parameters.count == 1,
                  let gridID = parameters.removeFirst() as? Int
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                mainView.gridClear(gridID: gridID)
              }

            case .gridCursorGoto:
              os_log("gridCursorGoto!")

            case .gridDestroy:
              await forEachParametersTuple { parameters in
                guard
                  parameters.count == 1,
                  let gridID = parameters.removeFirst() as? Int
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                mainView.gridDestroy(gridID: gridID)
              }

            case .winPos:
              await forEachParametersTuple { parameters in
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

                let gridFrame = GridRectangle(
                  origin: .init(x: x, y: y),
                  size: .init(width: width, height: height)
                )
                mainView.winPos(
                  gridID: gridID,
                  winRef: .init(data: winRef.data),
                  gridFrame: gridFrame
                )
              }

            case .winFloatPos:
              await forEachParametersTuple { parameters in
                guard
                  parameters.count == 8,
                  let gridID = parameters.removeFirst() as? Int,
                  let winRef = parameters.removeFirst() as? (data: Data, type: Int8),
                  let anchorType = parameters.removeFirst() as? String,
                  let anchorGridID = parameters.removeFirst() as? Int,
                  let anchorY = parameters.removeFirst() as? Double,
                  let anchorX = parameters.removeFirst() as? Double,
                  let focusable = parameters.removeFirst() as? Bool,
                  let zPosition = parameters.removeFirst() as? Int
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                mainView.winFloatPos(
                  gridID: gridID,
                  winRef: .init(data: winRef.data),
                  anchorType: anchorType,
                  anchorGridID: anchorGridID,
                  anchorX: anchorX,
                  anchorY: anchorY,
                  focusable: focusable,
                  zPosition: zPosition
                )
              }

            case .winHide:
              await forEachParametersTuple { parameters in
                guard
                  parameters.count == 1,
                  let gridID = parameters.removeFirst() as? Int
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                mainView.winHide(gridID: gridID)
              }

            case .winClose:
              await forEachParametersTuple { parameters in
                guard
                  parameters.count == 1,
                  let gridID = parameters.removeFirst() as? Int
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                mainView.winClose(gridID: gridID)
              }

            case .defaultColorsSet:
              await forEachParametersTuple { parameters in
                guard
                  parameters.count == 5,
                  let foregroundRGB = parameters.removeFirst() as? Int,
                  let backgroundRGB = parameters.removeFirst() as? Int,
                  let specialRGB = parameters.removeFirst() as? Int,
                  let _ = parameters.removeFirst() as? Int,
                  let _ = parameters.removeFirst() as? Int
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                await appearance.setDefaultColors(
                  foregroundRGB: foregroundRGB,
                  backgroundRGB: backgroundRGB,
                  specialRGB: specialRGB
                )
              }

            case .hlAttrDefine:
              await forEachParametersTuple { parameters in
                guard
                  parameters.count == 4,
                  let highlightID = parameters.removeFirst() as? Int,
                  let rgbAttr = parameters.removeFirst() as? [(String, MessageValue)],
                  let _ = parameters.removeFirst() as? [(String, MessageValue)],
                  let _ = parameters.removeFirst() as? [MessageValue]
                else {
                  throw RedrawNotificationParsingError.invalidParameterTypes
                }

                await appearance.apply(
                  nvimAttr: rgbAttr,
                  forHighlightID: highlightID
                )
              }

            case .flush:
              break
            }
          }
        }
      }
    }

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

    Task {
      for await keyPress in window.keyPresses {
        guard !Task.isCancelled else {
          break
        }

        do {
          try await messageRPC.request(
            method: "nvim_input",
            parameters: [keyPress.makeNvimKeyCode()]
          )

        } catch {
          os_log("nvim_input failed: \(error)")
        }
      }
    }
  }

  func showWindow() {
    self.window.becomeMain()
    self.window.makeKeyAndOrderFront(nil)
  }

  private let appearance: Appearance
  private let process: Process
  private let messageRPC: MessageRPC
  private let window: Window
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
