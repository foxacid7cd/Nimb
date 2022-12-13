// Copyright © 2022 foxacid7cd. All rights reserved.

import Cocoa
import Library
import Neovim
import OSLog

@NSApplicationMain @MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: AppKit.Notification) {
    do {
      let nvimInstance = try NvimInstance()
      self.nvimInstance = nvimInstance

      Task.detached {
        do {
          try await nvimInstance.task.value

          os_log("Nvim instance ended running.")

        } catch {
          os_log("Nvim instance failed: \(error)")
        }
      }

      os_log("Nvim started.")

    } catch {
      os_log("Nvim instance failed starting: \(error)")
    }
  }

  private var nvimInstance: NvimInstance?
}
