// Copyright © 2022 foxacid7cd. All rights reserved.

import Cocoa
import Neovim
import OSLog

actor AppCoordinator {
  init() {
    let appearance = Appearance()
    self.appearance = appearance

    os_log("Starting Neovim instance.")
    let neovimInstance = Instance()
    self.neovimInstance = neovimInstance

    Task {
      let messages = await neovimInstance.processErrorMessages
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

      for await message in messages {
        os_log("Neovim process standard error >> \(message)")
      }
    }

    states = .init(bufferingPolicy: .bufferingNewest(1)) { continuation in
      let task = Task {
        do {
          for try await state in await neovimInstance.states {
            guard !Task.isCancelled else {
              return
            }

            switch state {
            case .running:
              os_log("Neovim instance is running.")

              let uiEventBatchesTask = Task {
                for await uiEventBatch in await neovimInstance.api.uiEventBatches {
                  guard !Task.isCancelled else {
                    return
                  }

                  switch uiEventBatch {
                  case let .defaultColorsSet(events):
                    for try await event in events {
                      await appearance.setDefaultColors(
                        foregroundRGB: event.rgbFg,
                        backgroundRGB: event.rgbBg,
                        specialRGB: event.rgbSp
                      )
                    }

                  case let .hlAttrDefine(events):
                    try await withThrowingTaskGroup(of: Void.self) { group in
                      for try await event in events {
                        group.addTask {
                          await appearance.apply(
                            nvimAttr: event.rgbAttrs,
                            forHighlightWithID: event.id
                          )
                        }
                      }

                      try await group.waitForAll()
                    }

                  default:
                    break
                  }
                }
              }

              await withTaskCancellationHandler {
                do {
                  try await neovimInstance.api.nvimUIAttach(
                    width: 80,
                    height: 24,
                    options: [
                      "ext_multigrid": true,
                      "ext_hlstate": true,
                      "ext_cmdline": true,
                      "ext_messages": true,
                      "ext_popupmenu": true,
                      "ext_tabline": true,
                    ]
                  )
                  .check()

                  os_log("Neovim UI attached.")

                  continuation.yield(.running)

                } catch {
                  os_log("Neovim UI attach request failed with error (\(error)).")

                  await neovimInstance.terminate()
                }

              } onCancel: {
                uiEventBatchesTask.cancel()
              }
            }
          }

          os_log("Neovim instance finished running.")

        } catch {
          os_log("Neovim instance finished running with error (\(error)).")
        }

        continuation.finish()
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

  enum State {
    case running
  }

  let states: AsyncStream<State>

  private let appearance: Appearance
  private let neovimInstance: Instance
}
