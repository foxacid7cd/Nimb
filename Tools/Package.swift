// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "Tools",
  platforms: [.macOS(.v13)],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax", branch: "main"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    .package(path: "../Modules/NvimAPI"),
  ],
  targets: [
    .executableTarget(
      name: "generate",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "NvimAPI", package: "NvimAPI"),
      ],
      path: "",
      sources: ["Sources/generate"]
    ),
  ]
)
