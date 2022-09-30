import ProjectDescription

let dependencies = Dependencies(
  carthage: [],
  swiftPackageManager: [
    .remote(url: "https://github.com/a2/MessagePack.swift", requirement: .upToNextMajor(from: "4.0.0")),
    .remote(url: "https://github.com/stencilproject/Stencil", requirement: .upToNextMajor(from: "0.15.1")),
    .remote(url: "https://github.com/apple/swift-argument-parser", requirement: .upToNextMajor(from: "1.1.4"))
  ],
  platforms: [.macOS]
)
