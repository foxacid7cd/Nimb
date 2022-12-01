//
//  NvimInstance.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Backbone
import Cocoa
import MessagePack
import OSLog

@MainActor
class NvimInstance {
  init() {
    let appearance = Appearance()
    self.appearance = appearance

    let mainView = MainView(appearance: appearance)

    let window = Window(
      style: [.titled],
      contentView: mainView
    )
    self.window = window

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

    struct FileHandleWrapper: MessageDataSource, MessageDataDestination {
      var data: AnyAsyncThrowingSequence<Data> {
        let stream = AsyncStream<Data> { continuation in
          self.fileHandle.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData

            if data.isEmpty {
              continuation.finish()

            } else {
              continuation.yield(data)
            }
          }
        }

        return stream.eraseToAnyAsyncThrowingSequence()
      }

      var fileHandle: FileHandle

      func write(data: Data) async throws {
        try self.fileHandle.write(contentsOf: data)
      }
    }

    let packer = MessagePacker(
      dataDestination: FileHandleWrapper(
        fileHandle: standardInputPipe.fileHandleForWriting
      )
    )
    self.packer = packer

    let unpacker = MessageUnpacker(
      dataSource: FileHandleWrapper(
        fileHandle: standardOutputPipe.fileHandleForReading
      )
    )
    self.unpacker = unpacker

    let messageRPC = MessageRPC(packer: packer, unpacker: unpacker)
    self.messageRPC = messageRPC

    self.notificationsTask = Task {
      do {
        for try await notification in await messageRPC.notifications {
          guard !Task.isCancelled else {
            return
          }

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

      } catch {
        if process.isRunning == true {
          process.terminate()
        }
      }
    }

    self.inputTask = Task {
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

  func start() async throws {
    guard !self.started else {
      return
    }
    self.started = true

    await self.unpacker.start()
    await self.messageRPC.start()

    try self.process.run()

    self.window.becomeMain()
    self.window.makeKeyAndOrderFront(nil)

    let options = [("rgb", true), ("override", true), ("ext_multigrid", true)]
    try await self.messageRPC.request(method: "nvim_ui_attach", parameters: [120, 40, options])
  }

  func stop() async throws {
    if self.process.isRunning {
      self.process.terminate()
    }

    self.window.close()
    self.notificationsTask?.cancel()
    self.inputTask?.cancel()
  }

  private let appearance: Appearance
  private let window: Window
  private let process: Process
  private let packer: MessagePacker
  private let unpacker: MessageUnpacker
  private let messageRPC: MessageRPC

  private var notificationsTask: Task<Void, Never>?
  private var inputTask: Task<Void, Never>?
  private var started = false
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
