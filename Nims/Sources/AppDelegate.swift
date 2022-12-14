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
    os_log("Cocoa application did finish launching.")

    os_log("Starting coordinator.")
    let coordinator = Coordinator()
    self.coordinator = coordinator

    Task {
      for await state in coordinator.states {
        switch state {
        case .running:
          os_log("Coordinator is running.")
        }
      }

      os_log("Coordinator finished running.")

      NSApplication.shared.terminate(nil)
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    os_log("Cocoa application will terminate.")
  }

  private var coordinator: Coordinator?
}
