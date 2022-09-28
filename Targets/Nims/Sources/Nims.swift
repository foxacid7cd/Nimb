//
//  Nims.swift
//
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//

import AppKit

@main
enum Nims {
  static func main() {
    let application = NSApplication.shared
    NSApp.setActivationPolicy(.regular)

    let appDelegate = AppDelegate()
    application.delegate = appDelegate

    NSApp.activate(ignoringOtherApps: true)
    NSApp.run()
  }
}
