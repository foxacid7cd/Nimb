import ProjectDescription

let dependencies = Dependencies(
  carthage: [],
  swiftPackageManager: [
    .remote(url: "https://github.com/a2/MessagePack.swift", requirement: .upToNextMajor(from: "4.0.0")),
  ],
  platforms: [.macOS]
)
