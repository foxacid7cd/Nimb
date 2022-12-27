// Copyright © 2022 foxacid7cd. All rights reserved.

import AsyncAlgorithms
import Cocoa
import Neovim
import OSLog

class Coordinator {
  init() {
    //    let store = Store()
    //
    //    os_log("Starting Neovim instance")
    //    let neovimInstance = Process()
    //
    //    let errorMessagesTask = Task {
    //      let messages = await neovimInstance.processErrorMessages
    //        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    //        .filter { !$0.isEmpty }
    //
    //      for await message in messages {
    //        guard !Task.isCancelled else {
    //          return
    //        }
    //
    //        os_log("Neovim process standard error >> \(message)")
    //      }
    //    }
    //
    //    let states = AsyncStream<State>(bufferingPolicy: .unbounded) { continuation in
    //      let task = Task<Void, Never> {
    //        do {
    //          for try await state in await neovimInstance.states {
    //            guard !Task.isCancelled else {
    //              return
    //            }
    //
    //            switch state {
    //            case .running:
    //              os_log("Neovim instance is running")
    //
    //              let uiEventBatchesTask = Task {
    //                for await uiEventBatch in await neovimInstance.api.uiEventBatches {
    //                  guard !Task.isCancelled else {
    //                    return
    //                  }
    //
    //                  await store.apply(uiEventBatch)
    //                }
    //              }
    //              var viewModelsTask: Task<Void, Never>?
    //
    //              let cancel = {
    //                uiEventBatchesTask.cancel()
    //                viewModelsTask?.cancel()
    //              }
    //
    //              await withTaskCancellationHandler {
    //                do {
    //                  try await neovimInstance.api.nvimUIAttach(
    //                    width: 130,
    //                    height: 40,
    //                    options: [
    //                      "ext_multigrid": true,
    //                      "ext_hlstate": true,
    //                      "ext_cmdline": false,
    //                      "ext_messages": true,
    //                      "ext_popupmenu": true,
    //                      "ext_tabline": true,
    //                    ]
    //                  )
    //                  .check()
    //
    //                  os_log("Neovim UI attached")
    //
    //                  viewModelsTask = Task { @MainActor in
    //                    var viewController: ViewController?
    //                    var window: Window?
    //
    //                    for await (viewModel, effects) in store.viewModels {
    //                      guard !Task.isCancelled else {
    //                        return
    //                      }
    //
    //                      if effects.contains(.initial) {
    //                        let newViewController = ViewController()
    //                        viewController = newViewController
    //
    //                        let newWindow = Window(contentViewController: newViewController)
    //                        window = newWindow
    //
    //                        var keyPressesTask: Task<Void, Never>?
    //                        let cancel = { keyPressesTask?.cancel() }
    //
    //                        await withTaskCancellationHandler {
    //                          keyPressesTask = Task {
    //                            for await keyPress in newWindow.keyPresses {
    //                              guard !Task.isCancelled else {
    //                                return
    //                              }
    //
    //                              try? await neovimInstance.api.nvimInput(
    //                                keys: keyPress.makeNvimKeyCode()
    //                              )
    //                              .check()
    //                            }
    //                          }
    //
    //                        } onCancel: {
    //                          cancel()
    //                        }
    //
    //                        continuation.yield(.running)
    //                      }
    //
    //                      viewController!.render(
    //                        viewModel: viewModel,
    //                        effects: effects
    //                      )
    //
    //                      if !window!.isMainWindow, effects.contains(.canvasChanged) {
    //                        window!.makeMain()
    //                        window!.makeKeyAndOrderFront(nil)
    //                      }
    //                    }
    //                  }
    //                } catch {
    //                  os_log("Neovim UI attach request failed with error (\(error))")
    //                }
    //
    //                continuation.finish()
    //
    //              } onCancel: {
    //                cancel()
    //              }
    //            }
    //          }
    //
    //          os_log("Neovim instance finished running")
    //
    //        } catch {
    //          os_log("Neovim instance finished running with error (\(error))")
    //        }
    //
    //        continuation.finish()
    //      }
    //
    //      continuation.onTermination = { _ in
    //        errorMessagesTask.cancel()
    //        task.cancel()
    //
    //        Task {
    //          await neovimInstance.terminate()
    //        }
    //      }
    //    }
  }

  enum State { case running }

  // let states = AsyncStream<State>.
}
