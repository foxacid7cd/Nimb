// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "NvimAPI",
  platforms: [.macOS(.v13)],
  products: [
    .library(
      name: "NvimAPI",
      targets: ["NvimAPI"]
    ),
  ],
  dependencies: [
    .package(path: "../Backbone"),
  ],
  targets: [
    .target(
      name: "NvimAPI",
      dependencies: [
        .target(name: "msgpack"),
        .product(name: "Backbone", package: "Backbone"),
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
