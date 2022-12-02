//
//  AppDeletate.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Backbone
import Cocoa
import NvimAPI
import OSLog

@NSApplicationMain @MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: AppKit.Notification) {
    startNvimInstance()
  }

  private var nvimTask: Task<Void, Never>?

  private func startNvimInstance() {
    let nvimInstance = NvimInstance()

    nvimTask = Task {
      do {
        os_log("Starting nvim instance.")

        try await nvimInstance.run()
        os_log("Nvim instance finished running")

        NSApplication.shared.terminate(nil)

      } catch {
        os_log("Nvim instance finished running with error: \(error)")
      }
    }
  }
}
