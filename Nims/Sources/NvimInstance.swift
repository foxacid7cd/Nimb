// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import Cocoa
import Collections
import IdentifiedCollections
import Library
import MessagePack
import Neovim
import OSLog

actor NvimInstance {
  init() throws {
    let process = Process()
    self.process = process

    let executableURL = Bundle.main.url(forAuxiliaryExecutable: "nvim")!
    process.executableURL = executableURL
    process.arguments = [executableURL.relativePath, "--embed"]

    var environment = ProcessInfo.processInfo.environment
    environment["VIMRUNTIME"] = "/opt/homebrew/share/nvim/runtime"
    process.environment = environment

    process.terminationHandler = { process in
      switch process.terminationReason {
      case .uncaughtSignal:
        os_log("Process terminated due to uncaught signal.")

      case .exit:
        let exitStatus = process.terminationStatus
        os_log("Process terminated with exit status \(exitStatus).")

      default:
        break
      }
    }

    let channel = ProcessChannel(process: process)

    api = API(channel)

    //    let rpcService = RPCService(
//      destinationFileHandle: inputPipe.fileHandleForWriting,
//      sourceFileHandle: outputPipe.fileHandleForReading
//    )
//    self.store = Store(rpcService: rpcService)
//    self.notificationsTask = Task.detached {
//      do {
//        for try await notification in await caller.notifications() {
//          guard !Task.isCancelled else {
//            return
//          }
//
//          guard let method = NvimNotificationMethodName(rawValue: notification.method) else {
//            os_log("Unexpected nvim notification method: \(notification.method)")
//            return
//          }
//
//          switch method {
//          case .redraw:
//            for parameter in notification.parameters {
//              guard
//                var casted = parameter as? [Value],
//                !casted.isEmpty,
//                let uiEventName = casted.removeFirst() as? String
//              else {
//                os_log("Unexpected redraw notification structure")
//                continue
//              }
//
//              guard let name = RedrawUIEventName(rawValue: uiEventName) else {
//                os_log("Unexpected redraw UI event with name: \(uiEventName)")
//                continue
//              }
//
//              func forEachParametersTuple(_ body: (inout [Value]) async throws -> Void) async {
//                for element in casted {
//                  do {
//                    guard var parameters = element as? [Value] else {
//                      throw RedrawNotificationParsingError.uiEventParametersIsNotArray
//                    }
//
//                    try await body(&parameters)
//
//                  } catch {
//                    os_log("Redraw notification parsing failed: \(error)")
//                  }
//                }
//              }
//
//              switch name {
//              case .gridResize:
//                await forEachParametersTuple { parameters in
//                  guard
//                    parameters.count == 3,
//                    let rawID = parameters.removeFirst() as? Int,
//                    let width = parameters.removeFirst() as? Int,
//                    let height = parameters.removeFirst() as? Int
//                  else {
//                    throw RedrawNotificationParsingError.invalidParameterTypes
//                  }
//                  let id = Grid.ID(rawID)
//                  let size = Size(width: width, height: height)
//
//                  await self.store.gridResize(id: id, size: size)
//
//                  if id == 1 {
//                    let cellSize = await appearance.cellSize()
//                    await window.setContentSize(size * cellSize)
//                  }
//                }
//
//              case .gridLine:
//                var accumulator = TreeDictionary<Grid.ID, [(origin: Point, data: [Value])]>()
//
//                for element in casted {
//                  guard
//                    var parameters = element as? [Value],
//                    parameters.count == 4,
//                    let rawID = parameters.removeFirst() as? Int,
//                    let y = parameters.removeFirst() as? Int,
//                    let x = parameters.removeFirst() as? Int,
//                    let data = parameters.removeFirst() as? [Value]
//                  else {
//                    throw RedrawNotificationParsingError.invalidParameterTypes
//                  }
//                  let id = Grid.ID(rawID)
//                  let origin = Point(x: x, y: y)
//
//                  accumulator.updateValue(forKey: id, default: []) { parametersBatch in
//                    parametersBatch.append((origin, data))
//                  }
//                }
//
//                await self.store.gridLine(parametersBatches: accumulator)
//
//              case .gridClear:
//                await forEachParametersTuple { parameters in
//                  guard
//                    parameters.count == 1,
//                    let gridID = parameters.removeFirst() as? Int
//                  else {
//                    throw RedrawNotificationParsingError.invalidParameterTypes
//                  }
//
//                  await mainView.gridClear(gridID: gridID)
//                }
//
//              case .gridCursorGoto:
//                os_log("gridCursorGoto!")
//
//              case .gridDestroy:
//                await forEachParametersTuple { parameters in
//                  guard
//                    parameters.count == 1,
//                    let gridID = parameters.removeFirst() as? Int
//                  else {
//                    throw RedrawNotificationParsingError.invalidParameterTypes
//                  }
//
//                  await mainView.gridDestroy(gridID: gridID)
//                }
//
//              case .winPos:
//                await forEachParametersTuple { parameters in
//                  guard
//                    parameters.count == 6,
//                    let gridID = parameters.removeFirst() as? Int,
//                    let winRef = parameters.removeFirst() as? (data: Data, type: Int8),
//                    let y = parameters.removeFirst() as? Int,
//                    let x = parameters.removeFirst() as? Int,
//                    let width = parameters.removeFirst() as? Int,
//                    let height = parameters.removeFirst() as? Int
//                  else {
//                    throw RedrawNotificationParsingError.invalidParameterTypes
//                  }
//
//                  let gridFrame = Rectangle(
//                    origin: .init(x: x, y: y),
//                    size: .init(width: width, height: height)
//                  )
    ////                  mainView.winPos(
    ////                    gridID: gridID,
    ////                    winRef: .init(data: winRef.data),
    ////                    gridFrame: gridFrame
    ////                  )
//                }
//
//              case .winFloatPos:
//                await forEachParametersTuple { parameters in
//                  guard
//                    parameters.count == 8,
//                    let gridID = parameters.removeFirst() as? Int,
//                    let winRef = parameters.removeFirst() as? (data: Data, type: Int8),
//                    let anchorType = parameters.removeFirst() as? String,
//                    let anchorGridID = parameters.removeFirst() as? Int,
//                    let anchorY = parameters.removeFirst() as? Double,
//                    let anchorX = parameters.removeFirst() as? Double,
//                    let focusable = parameters.removeFirst() as? Bool,
//                    let zPosition = parameters.removeFirst() as? Int
//                  else {
//                    throw RedrawNotificationParsingError.invalidParameterTypes
//                  }
//
    ////                  mainView.winFloatPos(
    ////                    gridID: gridID,
    ////                    winRef: .init(data: winRef.data),
    ////                    anchorType: anchorType,
    ////                    anchorGridID: anchorGridID,
    ////                    anchorX: anchorX,
    ////                    anchorY: anchorY,
    ////                    focusable: focusable,
    ////                    zPosition: zPosition
    ////                  )
//                }
//
//              case .winHide:
//                await forEachParametersTuple { parameters in
//                  guard
//                    parameters.count == 1,
//                    let gridID = parameters.removeFirst() as? Int
//                  else {
//                    throw RedrawNotificationParsingError.invalidParameterTypes
//                  }
//
    ////                  mainView.winHide(gridID: gridID)
//                }
//
//              case .winClose:
//                await forEachParametersTuple { parameters in
//                  guard
//                    parameters.count == 1,
//                    let gridID = parameters.removeFirst() as? Int
//                  else {
//                    throw RedrawNotificationParsingError.invalidParameterTypes
//                  }
//
//                  await mainView.winClose(gridID: gridID)
//                }
//
//              case .defaultColorsSet:
//                await forEachParametersTuple { parameters in
//                  guard
//                    parameters.count == 5,
//                    let foregroundRGB = parameters.removeFirst() as? Int,
//                    let backgroundRGB = parameters.removeFirst() as? Int,
//                    let specialRGB = parameters.removeFirst() as? Int,
//                    let _ = parameters.removeFirst() as? Int,
//                    let _ = parameters.removeFirst() as? Int
//                  else {
//                    throw RedrawNotificationParsingError.invalidParameterTypes
//                  }
//
//                  await appearance.setDefaultColors(
//                    foregroundRGB: foregroundRGB,
//                    backgroundRGB: backgroundRGB,
//                    specialRGB: specialRGB
//                  )
//                }
//
//              case .hlAttrDefine:
//                await forEachParametersTuple { parameters in
//                  guard
//                    parameters.count == 4,
//                    let id = parameters.removeFirst() as? Int,
//                    let rgbAttr = parameters.removeFirst() as? [(String, Value)],
//                    let _ = parameters.removeFirst() as? [(String, Value)],
//                    let _ = parameters.removeFirst() as? [Value]
//                  else {
//                    throw RedrawNotificationParsingError.invalidParameterTypes
//                  }
//
//                  await appearance.apply(
//                    nvimAttr: rgbAttr,
//                    forID: .init(id)
//                  )
//                }
//
//              case .flush:
//                break
//              }
//            }
//          }
//        }
//
//      } catch {
//        if process.isRunning == true {
//          process.terminate()
//        }
//      }
//    }
//
//    self.inputTask = Task {
//      for await keyPress in window.keyPresses {
//        guard !Task.isCancelled else {
//          break
//        }
//
    ////        await caller.call(
    ////          method: "nvim_input",
    ////          parameters: [keyPress.makeNvimKeyCode()]
    ////        )
//      }
  }

  private let process: Process
  private let api: API

  private func startProcess() async throws {
    try await api.nvimUIAttach(
      width: 80,
      height: 24,
      options: [
        "rgb": true,
        "ext_multigrid": true,
        "ext_hlstate": true,
      ]
    )
    .check()
  }
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

private class ProcessChannel: Channel {
  init(process: Process) {
    let inputPipe = Pipe()
    process.standardOutput = inputPipe
    sourceFileHandle = inputPipe.fileHandleForReading

    let outputPipe = Pipe()
    process.standardInput = outputPipe
    destinationFileHandle = outputPipe.fileHandleForWriting
  }

  var dataBatches: AsyncStream<Data> {
    .init(reading: sourceFileHandle)
  }

  func write(_ data: Data) async throws {
    try destinationFileHandle.write(contentsOf: data)
  }

  private let sourceFileHandle: FileHandle
  private let destinationFileHandle: FileHandle
}
