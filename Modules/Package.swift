// swift-tools-version: 5.10

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "Modules",
  platforms: [.macOS(.v13)],
  products: [
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
    .package(url: "https://github.com/apple/swift-collections", from: "1.1.2"),
    .package(url: "https://github.com/apple/swift-syntax", from: "510.0.2"),
    .package(
      url: "https://github.com/apple/swift-argument-parser",
      from: "1.5.0"
    ),
    .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
    .package(
      url: "https://github.com/pointfreeco/swift-identified-collections",
      from: "1.1.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-case-paths",
      from: "1.3.2"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-overture",
      from: "0.5.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-custom-dump",
      from: "1.3.2"
    ),
    .package(
      url: "https://github.com/apple/swift-async-algorithms",
      branch: "main"
    ),
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
        .target(name: "Cmsgpack"),
      ]
    ),
    .target(
      name: "Library",
      dependencies: [
        .target(name: "Macros"),
        .product(name: "Collections", package: "swift-collections"),
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        .product(name: "Algorithms", package: "swift-algorithms"),
        .product(
          name: "IdentifiedCollections",
          package: "swift-identified-collections"
        ),
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "Overture", package: "swift-overture"),
        .product(name: "CustomDump", package: "swift-custom-dump"),
      ]
    ),
    .macro(
      name: "Macros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
      ]
    ),
    .systemLibrary(
      name: "Cmsgpack",
      pkgConfig: "msgpack-c",
      providers: [.brewItem(["msgpack"])]
    ),
  ]
)
