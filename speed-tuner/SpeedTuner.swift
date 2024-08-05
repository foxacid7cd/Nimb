// SPDX-License-Identifier: MIT

import AppKit
import ArgumentParser
import CustomDump
import Foundation
import System

@main
struct SpeedTuner: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "speed-tuner",
    shouldDisplay: true,
    subcommands: []
  )

  func run() async throws {
    let assetsDirectoryURL = Bundle.main.bundleURL.appending(
      component: "speed-tuner-assets",
      directoryHint: .isDirectory
    )
    let dataFileURL = assetsDirectoryURL.appending(
      component: "data.mpack",
      directoryHint: .notDirectory
    )
    let data = try Data(contentsOf: dataFileURL)

    let unpacker = Unpacker()
    let duration = try ContinuousClock().measure {
      let values = try unpacker.unpack(data)
      print("values: \(values.count)")
    }
    print("duration \(duration)")
  }
}
