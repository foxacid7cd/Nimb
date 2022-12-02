//
//  Generate.swift
//
//
//  Created by Yevhenii Matviienko on 01.12.2022.
//

import ArgumentParser
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

@main
struct Generate: ParsableCommand {
  @Argument(
    help: "The path to the destination directory where the source files are to be generated",
    completion: .directory
  )
  var generatedPath: String

  func run() throws {
    let destination = URL(fileURLWithPath: generatedPath, isDirectory: true)

    try FileManager.default.createDirectory(
      at: destination,
      withIntermediateDirectories: true,
      attributes: nil
    )
  }
}
