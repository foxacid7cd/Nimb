// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import Foundation
import MessagePack
import OSLog

public actor Instance {
  public init() {
    struct ProcessChannel: Channel, Sendable {
      var dataBatches: AsyncStream<Data> {
        outputPipe.fileHandleForReading.dataBatches
      }

      var errorMessages: AsyncStream<String> {
        .init(bufferingPolicy: .unbounded) { continuation in
          Task {
            var accumulator = Data()

            for await data in errorPipe.fileHandleForReading.dataBatches {
              accumulator.append(data)

              if let string = String(data: accumulator, encoding: .utf8) {
                accumulator.removeAll(keepingCapacity: true)

                continuation.yield(string)
              }
            }

            if !accumulator.isEmpty {
              continuation.yield("*\(accumulator.count) byte(s) of non UTF-8 data*")
            }
          }
        }
      }

      func write(_ data: Data) async throws {
        try inputPipe.fileHandleForWriting
          .write(contentsOf: data)
      }

      private let inputPipe = Pipe()
      private let outputPipe = Pipe()
      private let errorPipe = Pipe()

      func bind(to process: Process) {
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe
      }
    }
    let processChannel = ProcessChannel()
    processErrorMessages = processChannel.errorMessages

    let api = API(processChannel)
    self.api = api

    states = AsyncThrowingStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
      Task { @MainActor in
        let process = Process()
        let processObjectIdentifier = ObjectIdentifier(process)

        processChannel.bind(to: process)

        let executableURL = Bundle.main.url(forAuxiliaryExecutable: "nvim")!
        process.executableURL = executableURL
        process.arguments = [executableURL.relativePath, "--embed"]

        var environment = ProcessInfo.processInfo.environment
        environment["VIMRUNTIME"] = "/opt/homebrew/share/nvim/runtime"
        process.environment = environment

        do {
          try process.run()

        } catch {
          continuation.finish(throwing: error)
          return
        }

        continuation.yield(.running)

        await withTaskGroup(of: Void.self) { group in
          group.addTask { @MainActor in
            do {
              try await api.task.value

            } catch {
              continuation.finish(throwing: error)
              process.terminate()
            }
          }

          group.addTask { @MainActor in
            defer {
              api.task.cancel()
            }

            let termination = NotificationCenter.default
              .notifications(named: Process.didTerminateNotification)
              .compactMap { notification -> Void? in
                guard
                  let object = notification.object as? AnyObject,
                  ObjectIdentifier(object) == processObjectIdentifier
                else {
                  return nil
                }

                return ()
              }

            for await _ in termination {
              switch process.terminationReason {
              case .uncaughtSignal:
                continuation.finish(throwing: TerminationError.uncaughtSignal)
                return

              case .exit:
                let exitCode = Int(process.terminationStatus)

                if exitCode != 0 {
                  continuation.finish(throwing: TerminationError.exitWithNonzeroCode(exitCode))
                  return
                }

              default:
                assertionFailure("Unknown process termination reason: \(process.terminationReason).")
              }

              continuation.finish()
              return
            }
          }

          await group.waitForAll()
        }
      }
    }
  }

  public enum State {
    case running
  }

  public enum TerminationError: Error {
    case uncaughtSignal
    case exitWithNonzeroCode(Int)
  }

  public let api: API
  public let states: AsyncThrowingStream<State, Error>
  public let processErrorMessages: AsyncStream<String>
}
