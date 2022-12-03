// Copyright © 2022 foxacid7cd. All rights reserved.

import Backbone
import Cocoa
import NvimAPI
import OSLog

@NSApplicationMain @MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: AppKit.Notification) {
    Task {
      do {
        let nvimInstance = try NvimInstance()
        try await nvimInstance.run()

        os_log("Nvim instance ended running.")

      } catch {
        os_log("Nvim instance failed starting with error \(error).")
      }
    }
  }
}
