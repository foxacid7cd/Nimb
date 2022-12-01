//
//  AppDeletate.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 28.11.2022.
//

import Cocoa
import MessagePack
import NvimServiceAPI
import OSLog

@NSApplicationMain @MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    self.startNvimInstance()
  }

  private var nvimInstance: NvimInstance?

  private func startNvimInstance() {
    guard self.nvimInstance == nil else {
      return
    }

    let nvimInstance = NvimInstance()
    self.nvimInstance = nvimInstance

    Task {
      do {
        try await nvimInstance.start()

      } catch {
        fatalError("NvimInstance start failed: \(error)")
      }
    }
  }
}
