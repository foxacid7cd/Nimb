//
//  Nims.swift
//
//
//  Created by Yevhenii Matviienko on 22.09.2022.
//

import AppKit

@main
private enum Nims {
  private static let appDelegate = AppDelegate()

  static func main() async {
    let application = NSApplication.shared
    application.delegate = appDelegate
    application.run()
  }
}
