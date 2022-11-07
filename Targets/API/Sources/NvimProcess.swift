//
//  NvimProcess.swift
//  Nvim
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Foundation
import Library
import MessagePack
import RxCocoa
import RxSwift
import Socket

public class NvimProcess {
  @MainActor
  public init(input: Observable<KeyPress>, mouseInput: Observable<MouseInput>, executableURL: URL, runtimeURL: URL) {
    log(.info, "Nvim executable URL: \(executableURL.absoluteURL.relativePath)")

    let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "WXA9R8SW25.Nims")!
    self.unixSocketFileURL = containerURL.appendingPathComponent("\(UUID().uuidString).nvim", isDirectory: false)

    self.process.executableURL = executableURL
    self.process.arguments = ["--listen", self.unixSocketFileURL.absoluteURL.relativePath, "--headless"]

    self.process.standardOutput = Pipe()

    log(.info, "Nvim process arguments: \(self.process.arguments!)")

    var environment = [String: String]()
    environment["VIMRUNTIME"] = runtimeURL.absoluteURL.relativePath
    environment["PATH"] = ProcessInfo.processInfo.environment["PATH"]
    log(.info, "Nvim process environment: \(environment)")
    self.process.environment = environment

    let rpc = RPC(inputMessages: self.rpcInputSubject)
    self.rpc = rpc

    self.process.terminationHandler = { [weak self] process in
      self?.errorSubject.onNext(
        "Nvim process terminated with status \(process.terminationStatus), reason \(process.terminationReason)"
          .fail()
      )
    }

    self.process <~ input
      .map { $0.makeNvimKeyCode() }
      .bind(with: self) { nvimProcess, keyCode in
        Task {
          do {
            _ = try await nvimProcess.nvimInput(keys: keyCode)

          } catch {
            nvimProcess.errorSubject.onNext(
              "Failed nvim input"
                .fail(child: error.fail())
            )
          }
        }
      }

    self.process <~ mouseInput
      .bind(with: self) { nvimProcess, mouseInput in
        Task {
          do {
            _ = try await nvimProcess.nvimInputMouse(button: mouseInput.event.nvimButton, action: mouseInput.event.nvimAction, modifier: "", grid: mouseInput.gridID, row: mouseInput.point.row, col: mouseInput.point.column)

          } catch {
            nvimProcess.errorSubject.onNext(
              "Failed nvim input mouse"
                .fail(child: error.fail())
            )
          }
        }
      }
  }

  public func run() -> Observable<[NvimNotification]> {
    let runningProcess = Observable<Process>.create { observer in
      do {
        try self.process.run()

        observer.onNext(self.process)

      } catch {
        observer.onError(
          "failed running nvim process"
            .fail(child: error.fail())
        )
      }

      return Disposables.create {
        self.process.terminate()
      }
    }

    let values = runningProcess
      .map { _ -> Socket in
        let socket = try! Socket.create(family: .unix, type: .stream, proto: .unix)
        socket.readBufferSize = 16 * 1024 * 1024
        return socket
      }
      .flatMap { socket -> Observable<Socket> in
        .deferred {
          do {
            try socket.connect(
              to: self.unixSocketFileURL.absoluteURL.relativePath
            )
            return .just(socket)

          } catch {
            return .error(error)
          }
        }
        .delaySubscription(.milliseconds(100), scheduler: SerialDispatchQueueScheduler(qos: .userInitiated))
        .retry(3)
        .catch { error in
          self.errorSubject.onNext(error)
          return .empty()
        }
      }
      .flatMap { socket -> Observable<[Value]> in
        self.rpc.outputMessages
          .flatMap { messages -> Observable<Void> in
            for message in messages {
              let data = message.value.data
              try socket.write(from: data)
            }

            return .empty()
          }
          .catch { [weak self] error in
            self?.errorSubject.onNext(error)
            return .empty()
          }
          .subscribe()
          .disposed(by: self.disposeBag)

        return socket.unpack()
      }

    values
      .map { values in
        try values.map { try Message(value: $0) }
      }
      .catch { [weak self] error in
        self?.errorSubject.onNext(error)
        return .empty()
      }
      .bind(onNext: self.rpcInputSubject.onNext)
      .disposed(by: self.disposeBag)

    let notifications = self.rpc.notifications
      .flatMap { notifications in
        do {
          return Observable.just(
            try notifications
              .map { try NvimNotification(notification: $0) }
          )

        } catch {
          return Observable.error(
            "Failed parsing nvim notification"
              .fail(child: error.fail())
          )
        }
      }

    return Observable.merge([
      notifications,
      self.errorSubject.map { throw $0 }
    ])
    .observe(on: MainScheduler.instance)
  }

  public func terminate() {
    self.process.terminate()
  }

  let rpc: RPC

  private let process = Process()
  private let unixSocketFileURL: URL
  private let disposeBag = DisposeBag()
  private let rpcInputSubject = PublishSubject<[Message]>()
  private let errorSubject = PublishSubject<Error>()
}

private extension Socket {
  func unpack() -> Observable<[Value]> {
    .create { observer in
      let bufferSize = self.readBufferSize * 4

      var isCancelled = false
      var endIndex = 0

      withUnsafeTemporaryAllocation(of: CChar.self, capacity: bufferSize) { pointer in
        let baseAddress = pointer.baseAddress!
        let rawBaseAddress = UnsafeMutableRawPointer(baseAddress)

        DispatchQueue.global(qos: .userInitiated).async {
          repeat {
            do {
              let bytesCount = try self.read(
                into: baseAddress.advanced(by: endIndex),
                bufSize: bufferSize - endIndex,
                truncate: false
              )
              endIndex += bytesCount

              let data = Data(bytesNoCopy: pointer.baseAddress!, count: endIndex, deallocator: .none)
              var subdata = Subdata(data: data)
              var parsedValues = [Value]()

              do {
                while true {
                  let value: Value
                  (value, subdata) = try MessagePack.unpack(subdata)
                  parsedValues.append(value)
                }

              } catch MessagePackError.insufficientData {
                observer.onNext(parsedValues)

                let remainderAddress = baseAddress.advanced(
                  by: endIndex - subdata.count
                )
                rawBaseAddress.copyMemory(
                  from: remainderAddress,
                  byteCount: subdata.count
                )
                endIndex = subdata.count

              } catch {
                throw "Failed parsing values"
                  .fail(child: error.fail())
              }

            } catch {
              observer.onError(
                "Failed socket data read"
                  .fail(child: error.fail())
              )
            }
          } while !isCancelled
        }
      }

      return Disposables.create {
        self.close()

        isCancelled = true
      }
    }
  }
}
