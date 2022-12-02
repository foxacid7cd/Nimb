// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "Backbone",
  platforms: [.macOS(.v13)],
  products: [
    .library(
      name: "Backbone",
      targets: ["Backbone"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections", branch: "main"),
    .package(url: "https://github.com/apple/swift-async-algorithms", branch: "main"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "0.5.0"),
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.8.0"),
  ],
  targets: [
    .target(
      name: "Backbone",
      dependencies: [
        .product(name: "Collections", package: "swift-collections"),
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
        .product(name: "Tagged", package: "swift-tagged"),
      ]
    ),
  ]
)
