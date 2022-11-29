//
//  NvimProcess.swift
//  Nvim
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AsyncAlgorithms
import Foundation
import Library
import MessagePack

public class NvimProcess {
  public init(executableURL _: URL, runtimeURL _: URL) {
//    log(.info, "Nvim executable URL: \(executableURL.absoluteURL.relativePath)")
//
//    let errorChannel = AsyncChannel<Error>()
//    self.errorChannel = errorChannel
//
//    let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "WXA9R8SW25.Nims")!
//    self.unixSocketFileURL = containerURL.appendingPathComponent("\(UUID().uuidString).nvim", isDirectory: false)
//
//    let process = Process()
//    self.process = process
//
//    process.executableURL = executableURL
//    process.arguments = ["--listen", self.unixSocketFileURL.absoluteURL.relativePath, "--headless"]
//    process.standardOutput = Pipe()
//
//    log(.info, "Nvim process arguments: \(self.process.arguments!)")
//
//    var environment = [String: String]()
//    environment["VIMRUNTIME"] = runtimeURL.absoluteURL.relativePath
//    environment["PATH"] = ProcessInfo.processInfo.environment["PATH"]
//    log(.info, "Nvim process environment: \(environment)")
//    process.environment = environment
//
//    let terminationChannel = AsyncChannel<(Int32, Process.TerminationReason)>()
//    process.terminationHandler = { process in
//      let status = process.terminationStatus
//      let reason = process.terminationReason
//
//      Task {
//        await terminationChannel.send((status, reason))
//      }
//    }
//
//    Task {
//      for await (status, reason) in terminationChannel {
//        await errorChannel.send(
//          "Nvim process terminated with status \(status), reason \(reason)"
//            .fail()
//        )
//      }
//    }
  }

  deinit {
    self.inputTask?.cancel()
    self.outputTask?.cancel()
  }

  public var notifications: AnyAsyncSequence<[NvimNotification]> {
    self.rpc.notifications
      .map { try $0.map { try NvimNotification(notification: $0) } }
      .eraseToAnyAsyncSequence()
  }

  public var error: AnyAsyncSequence<Error> {
    fatalError()
    // self.errorChannel.eraseToAnyAsyncSequence()
  }

  public func register(input: Input) {
    Task {
      do {
        switch input {
        case let .keyboard(keyPress):
          _ = try await self.nvimInput(
            keys: keyPress.makeNvimKeyCode()
          )

        case let .mouse(mouseInput):
          _ = try await self.nvimInputMouse(
            button: mouseInput.event.nvimButton,
            action: mouseInput.event.nvimAction,
            modifier: "",
            grid: mouseInput.gridID,
            row: mouseInput.point.row,
            col: mouseInput.point.column
          )
        }

      } catch {
        fatalError()
//        await self.errorChannel.send(
//          "NvimProcess input failed"
//            .fail(child: error.fail())
//        )
      }
    }
  }

  public func run() {
//    Task {
//      do {
//        try self.process.run()
//
//        // let socket = try await self.createSocket()
//        // self.setup(socket: socket)
//
//      } catch {
//        await self.errorChannel.send(
//          "failed running nvim process"
//            .fail(child: error.fail())
//        )
//      }
//    }
  }

  public func terminate() {
    // self.process.terminate()
  }

  static let dispatchQueue = DispatchQueue(
    label: "\(Bundle.main.bundleIdentifier!).\(NvimProcess.self)",
    qos: .userInteractive
  )

  let rpc = RPC()

  // private let process: Process
  // private let unixSocketFileURL: URL
  // private let errorChannel: AsyncChannel<Error>
  private var inputTask: Task<Void, Never>?
  private var outputTask: Task<Void, Never>?

  //  private func setup(socket: Socket) {
//    self.inputTask = Task {
//      do {
//        for try await values in socket.unpack() {
//          guard !Task.isCancelled else {
//            return
//          }
//
//          let messages = try values.map { try Message(value: $0) }
//          await self.rpc.send(inputMessages: messages)
//        }
//
//      } catch {
//        await self.errorChannel.send(
//          "Error unpacking socket"
//            .fail(child: error.fail())
//        )
//      }
//    }
//
//    self.outputTask = Task {
//      do {
//        for try await messages in self.rpc.outputMessages {
//          for message in messages {
//            guard !Task.isCancelled else {
//              return
//            }
//
//            let data = message.value.data
//            try socket.write(from: data)
//          }
//        }
//
//      } catch {
//        await self.errorChannel.send(
//          "Error sending messages"
//            .fail(child: error.fail())
//        )
//      }
//    }
  //  }
//
  //  private func createSocket() async throws -> Socket {
//    try await withCheckedThrowingContinuation { continuation in
//      Task {
//        let tries = 3
//
//        for i in 0 ..< tries {
//          do {
//            try await Task.sleep(nanoseconds: NSEC_PER_SEC / 10)
//
//            let socket = try Socket.create(family: .unix, type: .stream, proto: .unix)
//            socket.readBufferSize = 4 * 1024 * 1024
//            try socket.connect(to: self.unixSocketFileURL.absoluteURL.relativePath)
//
//            continuation.resume(returning: socket)
//            break
//
//          } catch {
//            if i == tries - 1 {
//              continuation.resume(
//                throwing: "Failed connecting to socket"
//                  .fail(child: error.fail())
//              )
//            }
//          }
//        }
//      }
//    }
  //  }
}

//
// private extension Socket {
//  func unpack() -> AsyncThrowingStream<[Value], Swift.Error> {
//    .init { continuation in
//      let task = Task {
//        let bufferSize = self.readBufferSize * 4
//
//        var endIndex = 0
//        var buffer = Data(repeating: 0, count: bufferSize)
//
//        repeat {
//          do {
//            let data = try await self.read()
//            buffer.replaceSubrange(endIndex ..< endIndex + data.count, with: data)
//            endIndex += data.count
//
//            var subdata = Subdata(data: buffer, startIndex: 0, endIndex: endIndex)
//            var parsedValues = [Value]()
//
//            do {
//              while true {
//                let value: Value
//                (value, subdata) = try MessagePack.unpack(subdata)
//                parsedValues.append(value)
//              }
//
//            } catch MessagePackError.insufficientData {
//              continuation.yield(parsedValues)
//
//              let remainder = subdata.data
//              buffer.replaceSubrange(0 ..< remainder.count, with: remainder)
//              endIndex = remainder.count
//
//            } catch {
//              let fail = "Failed parsing values"
//                .fail(child: error.fail())
//
//              continuation.finish(throwing: fail)
//            }
//
//          } catch {
//            continuation.finish(
//              throwing: "Failed socket data read"
//                .fail(child: error.fail())
//            )
//          }
//        } while !Task.isCancelled
//      }
//
//      continuation.onTermination = { _ in
//        task.cancel()
//      }
//    }
//  }
//
//  func read() async throws -> Data {
//    try await withCheckedThrowingContinuation { continuation in
//      NvimProcess.dispatchQueue.async {
//        do {
//          var data = Data()
//          try self.read(into: &data)
//          continuation.resume(returning: data)
//
//        } catch {
//          continuation.resume(throwing: error)
//        }
//      }
//    }
//  }
// }
