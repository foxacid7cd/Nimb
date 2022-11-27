// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "PackageName",
    dependencies: [
        .package(url: "https://github.com/a2/MessagePack.swift", from: "4.0.0"),
        .package(url: "https://github.com/stencilproject/Stencil", from: "0.15.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.1.4"),
        .package(url: "https://github.com/apple/swift-async-algorithms", branch: "main"),
        .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.5.0"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "0.1.0"),
        .package(url: "https://github.com/Kitura/BlueSocket", from: "2.0.2"),
        .package(url: "https://github.com/apple/swift-collections", branch: "main"),
    ]
)