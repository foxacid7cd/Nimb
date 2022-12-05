// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "Tools",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "generate", targets: ["generate"]),
    .library(name: "GenerateLibrary", targets: ["GenerateLibrary"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax", branch: "main"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    .package(path: "../Modules"),
  ],
  targets: [
    .executableTarget(
      name: "generate",
      dependencies: [
        .target(name: "GenerateLibrary"),
      ]
    ),
    .target(
      name: "GenerateLibrary",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "MessagePack", package: "Modules"),
      ]
    ),
    .testTarget(
      name: "GenerateLibraryTests",
      dependencies: [
        .target(name: "GenerateLibrary"),
      ],
      resources: [
        .copy("Resources/metadata.msgpack")
      ]
    ),
  ]
)
