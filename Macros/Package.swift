// swift-tools-version: 5.10

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "MacrosPackage",
  platforms: [.macOS(.v13)],
  products: [
    .library(
      name: "MacrosLibrary",
      targets: ["MacrosTarget"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax.git", branch: "main"),
  ],
  targets: [
    .macro(
      name: "MacrosTarget",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
      ]
    ),
  ]
)
