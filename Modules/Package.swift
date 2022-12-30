// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "Modules",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "NimsFeature", targets: ["NimsFeature"]),
    .library(name: "InstanceFeature", targets: ["InstanceFeature"]),
    .library(name: "Neovim", targets: ["Neovim"]),
    .executable(name: "generate", targets: ["generate"]),
    .library(name: "GenerateLibrary", targets: ["GenerateLibrary"]),
    .library(
      name: "MessagePack",
      targets: ["MessagePack"]
    ),
    .library(
      name: "Library",
      targets: ["Library"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections", branch: "main"),
    .package(url: "https://github.com/apple/swift-async-algorithms", branch: "main"),
    .package(url: "https://github.com/apple/swift-syntax", branch: "main"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    .package(url: "https://github.com/apple/swift-algorithms", branch: "main"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "0.5.0"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", branch: "main"),
    .package(url: "https://github.com/pointfreeco/swift-overture", branch: "main"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", branch: "main"),
    .package(url: "https://github.com/pointfreeco/swift-tagged", branch: "main")
  ],
  targets: [
    .target(
      name: "NimsFeature",
      dependencies: [
        .target(name: "InstanceFeature")
      ]
    ),
    .target(
      name: "InstanceFeature",
      dependencies: [
        .target(name: "Neovim")
      ]
    ),
    .target(
      name: "Neovim",
      dependencies: [
        .target(name: "MessagePack")
      ]
    ),
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
        .target(name: "MessagePack"),
      ]
    ),
    .testTarget(
      name: "GenerateLibraryTests",
      dependencies: [
        .target(name: "GenerateLibrary"),
      ],
      resources: [
        .copy("Resources/metadata.msgpack"),
      ]
    ),
    .target(
      name: "MessagePack",
      dependencies: [
        .target(name: "Library"),
        .target(name: "msgpack"),
      ]
    ),
    .target(
      name: "Library",
      dependencies: [
        .product(name: "Collections", package: "swift-collections"),
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        .product(name: "Algorithms", package: "swift-algorithms"),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "Overture", package: "swift-overture"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "Tagged", package: "swift-tagged")
      ]
    ),
    .systemLibrary(
      name: "msgpack",
      pkgConfig: "msgpack",
      providers: [
        .brewItem(["msgpack"])
      ]
    ),
  ]
)
