// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "Modules",
  platforms: [.macOS(.v13)],
  products: [
    .library(
      name: "Neovim",
      targets: ["Neovim"]
    ),
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
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "0.5.0"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", branch: "main"),
    .package(url: "https://github.com/pointfreeco/swift-overture", branch: "main"),
  ],
  targets: [
    .target(
      name: "Neovim",
      dependencies: [
        .target(name: "MessagePack"),
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
        .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "Overture", package: "swift-overture"),
      ]
    ),
    .systemLibrary(
      name: "msgpack",
      pkgConfig: "msgpack",
      providers: [
        .brewItem(["msgpack"]),
      ]
    ),
  ]
)
