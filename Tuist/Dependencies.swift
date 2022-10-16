import ProjectDescription

let dependencies = Dependencies(
  carthage: [],
  swiftPackageManager: [
    .remote(url: "https://github.com/a2/MessagePack.swift", requirement: .upToNextMajor(from: "4.0.0")),
    .remote(url: "https://github.com/stencilproject/Stencil", requirement: .upToNextMajor(from: "0.15.1")),
    .remote(url: "https://github.com/apple/swift-argument-parser", requirement: .upToNextMajor(from: "1.1.4")),
    .remote(url: "https://github.com/apple/swift-async-algorithms", requirement: .branch("main")),
    .remote(url: "https://github.com/ReactiveX/RxSwift", requirement: .upToNextMajor(from: "6.5.0"))
  ],
  platforms: [.macOS]
)
