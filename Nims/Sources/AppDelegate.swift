//
//  AppDeletate.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Cocoa
import MessagePackRPC
import OSLog

@NSApplicationMain @MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: AppKit.Notification) {
    self.startNvimInstance()
  }

  private var nvimTask: Task<Void, Never>?

  private func startNvimInstance() {
    let nvimInstance = NvimInstance()

    self.nvimTask = Task {
      do {
        try await nvimInstance.run()
        os_log("Nvim instance finished running")

      } catch {
        os_log("Nvim instance finished running with error: \(error)")
      }
    }
  }
}
