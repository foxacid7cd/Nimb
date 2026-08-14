// SPDX-License-Identifier: MIT

import ProjectDescription

/// Shared pieces of the Nimb project graph.
///
/// This is the parity manifest: it reproduces the hand-maintained
/// Nimb.xcodeproj exactly — same four targets, same duplicated source
/// memberships, same bridging headers — so that the build-system swap can be
/// validated independently of any source reorganisation.
public enum Nimb {
  public static let destinations: Destinations = .macOS
  public static let deploymentTargets: DeploymentTargets = .macOS("15.6")

  /// The prebuilt msgpack-c archive. Adding it as a dependency gives us the
  /// link entry, HEADER_SEARCH_PATHS for `publicHeaders` and
  /// LIBRARY_SEARCH_PATHS for the archive's directory, which together replace
  /// the hand-written search paths in the old project.
  ///
  /// `swiftModuleMap` is deliberately nil for now: the three bridging headers
  /// are still in place, and swapping them for a module map is a separate,
  /// riskier step.
  public static let msgpack: TargetDependency = .library(
    path: "Third-Party/msgpack-c/libmsgpack-c.a",
    publicHeaders: "Third-Party/msgpack-c/include",
    swiftModuleMap: nil,
  )

  /// Files under Nimb/Sources that the command line tools compile into
  /// themselves. In the old project these were duplicate PBXBuildFile entries;
  /// they are reproduced verbatim here and go away when the code is split into
  /// real modules.
  public static let sharedWithTools: [String] = [
    "Nimb/Sources/Library/AsyncFileHandle.swift",
    "Nimb/Sources/OSLog.swift",
    "Nimb/Sources/StateActor.swift",
  ]

  /// Additionally compiled into `generate` and `speed-tuner`.
  public static let sharedMessagePack: [String] = [
    "Nimb/Sources/Library/Failure.swift",
    "Nimb/Sources/Library/Macros.swift",
    "Nimb/Sources/MessagePack/Message.swift",
    "Nimb/Sources/MessagePack/Packer.swift",
    "Nimb/Sources/MessagePack/Unpacker.swift",
    "Nimb/Sources/MessagePack/Value.swift",
  ]

  /// Additionally compiled into `generate` only.
  public static let sharedWithGenerate: [String] = [
    "Nimb/Sources/Library/ArrayExtensions.swift",
    "Nimb/Sources/Library/AsyncSequence+Throttle.swift",
    "Nimb/Sources/Library/CustomDumpHelpers.swift",
    "Nimb/Sources/Library/IntKeyedDictionary.swift",
    "Nimb/Sources/Library/IntegerGeometry.swift",
    "Nimb/Sources/Library/NSFontCellSize.swift",
    "Nimb/Sources/Library/TwoDimensionalArray.swift",
    "Nimb/Sources/MessagePack/Channel.swift",
    "Nimb/Sources/MessagePack/RPC.swift",
  ]

  /// The Neovim API bindings, produced by `make generate` and git-ignored.
  /// Declared as generated so the project references them even on a clean
  /// checkout where they do not exist yet.
  public static let generatedSources: [SourceFileGlob] = [
    .generated("Nimb/Sources/generated/APIError.swift"),
    .generated("Nimb/Sources/generated/APIFunctions.swift"),
    .generated("Nimb/Sources/generated/References.swift"),
    .generated("Nimb/Sources/generated/UIEvent.swift"),
    .generated("Nimb/Sources/generated/UIOption.swift"),
  ]

  private static let base: SettingsDictionary = [
    "SWIFT_VERSION": "6.0",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "SWIFT_UPCOMING_FEATURE_GLOBAL_CONCURRENCY": "YES",
    "SWIFT_DEFAULT_ACTOR_ISOLATION": "nonisolated",
    "DEAD_CODE_STRIPPING": "YES",
    "CODE_SIGN_STYLE": "Automatic",
    "DEVELOPMENT_TEAM": "",
    "CLANG_ENABLE_MODULES": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "ENABLE_HARDENED_RUNTIME": "NO",
    "MTL_FAST_MATH": "YES",
  ]

  public static func settings(
    base extra: SettingsDictionary = [:],
    debug: SettingsDictionary = [:],
    release: SettingsDictionary = [:],
  )
    -> Settings
  {
    .settings(
      base: base.merging(extra) { $1 },
      configurations: [
        .debug(name: "Debug", settings: [
          "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)",
          "GCC_PREPROCESSOR_DEFINITIONS": "DEBUG=1 $(inherited)",
          "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
          "GCC_OPTIMIZATION_LEVEL": "0",
          "ONLY_ACTIVE_ARCH": "YES",
          "DEBUG_INFORMATION_FORMAT": "dwarf",
          "ENABLE_TESTABILITY": "YES",
          "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
        ].merging(debug) { $1 }),
        .release(name: "Release", settings: [
          "SWIFT_OPTIMIZATION_LEVEL": "-O",
          "SWIFT_COMPILATION_MODE": "wholemodule",
          "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
          "ENABLE_NS_ASSERTIONS": "NO",
          "MTL_ENABLE_DEBUG_INFO": "NO",
        ].merging(release) { $1 }),
      ],
      defaultSettings: .recommended,
    )
  }
}
