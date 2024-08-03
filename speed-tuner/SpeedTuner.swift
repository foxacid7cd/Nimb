//
//  SpeedTuner1.swift
//  speed-tuner
//
//  Created by Yevhenii Matviienko on 03.08.2024.
//

import Foundation
import ArgumentParser


@main
struct SpeedTuner: AsyncParsableCommand {
  static let configuration = CommandConfiguration(commandName: "speed-tuner", shouldDisplay: true, subcommands: [CollectMsgpackData.self])
  
  func run() async throws {
    print("SpeedTuner!")
  }
}
