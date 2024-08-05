// SPDX-License-Identifier: MIT

import ArgumentParser
import Foundation

@main
struct SpeedTuner: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "speed-tuner",
    shouldDisplay: true,
    subcommands: []
  )

  func run() async throws {
    print("SpeedTuner!")
  }
}
