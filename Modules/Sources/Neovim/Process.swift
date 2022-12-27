// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import Foundation
import MessagePack
import OSLog

@globalActor public actor ProcessActor { public static let shared = ProcessActor() }

public actor Process {
  public init() {
    let processChannel = ProcessChannel()
    processErrorMessages = processChannel.errorMessages

    let api = API(processChannel)
    self.api = api

    let terminateCalls: AsyncStream<Void>
    (_terminate, terminateCalls) = AsyncChannel.pipe()

    states = .init { continuation in
      let task = Task { @ProcessActor in let process = Foundation.Process()
        processChannel.bind(to: process)

        let executableURL = Bundle.main.url(forAuxiliaryExecutable: "nvim")!
        process.executableURL = executableURL
        process.arguments = [executableURL.relativePath, "--embed"]

        var environment = ProcessInfo.processInfo.environment
        environment["VIMRUNTIME"] = "/opt/homebrew/share/nvim/runtime"
        process.environment = environment

        let terminateProcess = { @Sendable @ProcessActor in process.terminate() }

        let terminateCallsTask = Task {
          for await _ in terminateCalls {
            guard !Task.isCancelled else { return }

            terminateProcess()
            return
          }
        }

        await withTaskCancellationHandler {
          do {
            try process.run()

          } catch {
            continuation.finish(throwing: error)
            return
          }

          continuation.yield(.running)

          await withTaskGroup(of: Void.self) { group in
            group.addTask {
              do {
                try await api.task.value

              } catch {
                guard !Task.isCancelled else { return }

                continuation.finish(throwing: error)
                await terminateProcess()
              }
            }

            group.addTask { @ProcessActor in
              let processObjectIdentifier = ObjectIdentifier(process)

              let termination = NotificationCenter.default
                .notifications(named: Foundation.Process.didTerminateNotification)
                .compactMap { notification -> Void? in
                  guard let object = notification.object as? AnyObject,
                    ObjectIdentifier(object) == processObjectIdentifier
                  else { return nil }

                  return ()
                }

              for await _ in termination {
                guard !Task.isCancelled else { return }

                switch process.terminationReason {
                case .uncaughtSignal: continuation.finish(throwing: TerminationError.uncaughtSignal)

                case .exit:
                  let exitCode = Int(process.terminationStatus)

                  if exitCode != 0 {
                    continuation.finish(throwing: TerminationError.exitWithNonzeroCode(exitCode))
                  }

                default:
                  assertionFailure(
                    "Unknown process termination reason (\(process.terminationReason.rawValue))."
                  )
                }

                continuation.finish()
              }
            }

            await group.waitForAll()
          }

        } onCancel: {
          terminateCallsTask.cancel()

          Task { await terminateProcess() }
        }
      }

      continuation.onTermination = { termination in
        api.task.cancel()

        switch termination {
        case .cancelled:
          task.cancel()
        default:
          break
        }
      }
    }
  }

  public enum State { case running }

  public enum TerminationError: Error {
    case uncaughtSignal
    case exitWithNonzeroCode(Int)
  }

  public let api: API
  public let states: AsyncThrowingStream<State, Error>
  public let processErrorMessages: AsyncStream<String>

  public func terminate() async { await _terminate(()) }

  private let _terminate: @Sendable (()) async -> Void

  private struct ProcessChannel: Channel, Sendable {
    var dataBatches: AsyncStream<Data> { outputPipe.fileHandleForReading.dataBatches }

    var errorMessages: AsyncStream<String> {
      .init { continuation in
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
            assertionFailure("Failed decoding UTF-8 String from data \(accumulator).")
          }

          continuation.finish()
        }
      }
    }

    func write(_ data: Data) async throws {
      try inputPipe.fileHandleForWriting.write(contentsOf: data)
    }

    private let inputPipe = Pipe()
    private let outputPipe = Pipe()
    private let errorPipe = Pipe()

    func bind(to process: Foundation.Process) {
      process.standardInput = inputPipe
      process.standardOutput = outputPipe
      process.standardError = errorPipe
    }
  }
}
