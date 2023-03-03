// SPDX-License-Identifier: MIT

import AsyncAlgorithms
import Foundation
import Library
import MessagePack
import OSLog

@globalActor
public actor ProcessActor { public static let shared = ProcessActor() }

public actor Process {
  public let api: API<ProcessChannel>

  public init(
    arguments: [String] = [],
    environmentOverlay: [String: String] = [:]
  ) {
    let processChannel = ProcessChannel()
    processErrorMessages = processChannel.errorMessages

    let rpc = RPC(processChannel)
    let api = API(rpc)
    self.api = api

    let terminateCalls: AsyncStream<Void>
    (_terminate, terminateCalls) = AsyncChannel.pipe()

    states = .init { continuation in
      let task = Task { @ProcessActor in let process = Foundation.Process()
        processChannel.bind(to: process)

        let executableURL = Bundle.main.url(forAuxiliaryExecutable: "nvim")!
        let command = ([executableURL.relativePath, "--embed"] + arguments)
          .joined(separator: " ")

        process.executableURL = .init(filePath: "/bin/zsh")
        process.arguments = ["-l", "-c", command]

        var environment = ProcessInfo.processInfo.environment
        environment["VIMRUNTIME"] = "/opt/homebrew/share/nvim/runtime"
        environment.merge(environmentOverlay, uniquingKeysWith: { $1 })
        process.environment = environment

        let terminateProcess = { @Sendable @ProcessActor in process.terminate() }

        let terminateCallsTask = Task {
          for await _ in terminateCalls {
            guard !Task.isCancelled else {
              return
            }

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
            group.addTask { @ProcessActor in
              let processObjectIdentifier = ObjectIdentifier(process)

              let termination = NotificationCenter.default
                .notifications(named: Foundation.Process.didTerminateNotification)
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
                guard !Task.isCancelled else {
                  return
                }

                switch process.terminationReason {
                case .uncaughtSignal:
                  continuation.finish(throwing: TerminationError.uncaughtSignal)

                case .exit:
                  let exitCode = Int(process.terminationStatus)

                  if exitCode != 0 {
                    continuation.finish(throwing: TerminationError.exitWithNonzeroCode(exitCode))
                  }

                @unknown default:
                  break
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
        switch termination {
        case .cancelled:
          task.cancel()

        default:
          break
        }
      }
    }
  }

  public enum State: Sendable { case running }

  public enum TerminationError: Error {
    case uncaughtSignal
    case exitWithNonzeroCode(Int)
  }

  public let states: AsyncThrowingStream<State, Error>
  public let processErrorMessages: AsyncStream<String>

  public func terminate() async { await _terminate(()) }

  public struct ProcessChannel: Channel, Sendable {
    public var dataBatches: AsyncStream<Data> { outputPipe.fileHandleForReading.dataBatches }

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

    public func write(_ data: Data) async throws {
      try inputPipe.fileHandleForWriting.write(contentsOf: data)
    }

    func bind(to process: Foundation.Process) {
      process.standardInput = inputPipe
      process.standardOutput = outputPipe
      process.standardError = errorPipe
    }

    private let inputPipe = Pipe()
    private let outputPipe = Pipe()
    private let errorPipe = Pipe()
  }

  private let _terminate: @Sendable (()) async -> Void
}
