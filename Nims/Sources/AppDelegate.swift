// Copyright © 2022 foxacid7cd. All rights reserved.

import CasePaths
import Cocoa
import Library
import MessagePack
import Neovim
import OSLog

@NSApplicationMain @MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: AppKit.Notification) {
    startNeovimInstance()
  }

  private func startNeovimInstance() {
    os_log("Starting neovim instance.")

    let instance = Instance()

    Task {
      for await message in await instance.processErrorMessages {
        os_log("Neovim process standard error output:\n\(message)")
      }
    }

    Task {
      do {
        for try await state in await instance.states {
          switch state {
          case .running:
            os_log("Neovim instance is running.")

            Task {
              for await uiEventBatch in await instance.api.uiEventBatches {
                switch uiEventBatch {
                case let .gridResize(events):
                  for try await event in events {
                    print(event)
                  }

                case let .gridLine(events):
                  for try await event in events {
                    print(event)
                  }

                default:
                  break
                }
              }
            }

            do {
              try await instance.api.nvimUIAttach(
                width: 80,
                height: 24,
                options: [
                  "rgb": true,
                  "ext_multigrid": true,
                  "ext_hlstate": true,
                ]
              )
              .check()

            } catch {
              os_log("Neovim API request failed with error (\(error)).")
            }
          }
        }

        os_log("Neovim instance finished running.")

      } catch {
        os_log("Neovim instance finished running with error (\(error)).")
      }
    }
  }
}
