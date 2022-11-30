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
    self.nvimInstance.showWindow()
  }

  private lazy var nvimInstance = NvimInstance()
}
