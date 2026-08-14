// SPDX-License-Identifier: MIT

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Nimb",
  organizationName: "foxacid7cd",
  options: .options(
    automaticSchemesOptions: .enabled(),
    disableBundleAccessors: true,
    // The app uses Xcode's own generated asset symbols
    // (ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS), so
    // Tuist's synthesized accessors are redundant — and they reference
    // Bundle.module, which disableBundleAccessors removes.
    disableSynthesizedResourceAccessors: true,
  ),
  packages: [
    // Xcode's native SPM integration, matching the hand-maintained project.
    // Tuist's own XcodeProj-based integration is not used here because it does
    // not pass -package-name, so packages that use the `package` access level
    // across their modules (swift-collections, swift-syntax) fail to build.
    .remote(url: "https://github.com/apple/swift-collections.git", requirement: .upToNextMajor(from: "1.6.0")),
    .remote(url: "https://github.com/apple/swift-algorithms.git", requirement: .upToNextMajor(from: "1.2.1")),
    .remote(url: "https://github.com/apple/swift-argument-parser.git", requirement: .upToNextMajor(from: "1.8.2")),
    .remote(url: "https://github.com/swiftlang/swift-syntax.git", requirement: .upToNextMajor(from: "603.0.2")),
    .remote(url: "https://github.com/pointfreeco/swift-case-paths.git", requirement: .upToNextMajor(from: "1.9.1")),
    .remote(url: "https://github.com/pointfreeco/swift-custom-dump.git", requirement: .upToNextMajor(from: "1.7.0")),
  ],
  settings: .settings(
    base: ["SDKROOT": "macosx"],
    defaultSettings: .recommended,
  ),
  targets: [
    // ── Macro plugin ────────────────────────────────────────────────────
    .target(
      name: "NimbMacros",
      destinations: Nimb.destinations,
      product: .macro,
      bundleId: "foxacid7cd.NimbMacros",
      deploymentTargets: Nimb.deploymentTargets,
      infoPlist: .default,
      sources: ["Sources/NimbMacros/**"],
      dependencies: [
        .package(product: "SwiftSyntaxMacros"),
        .package(product: "SwiftCompilerPlugin"),
      ],
      settings: Nimb.settings(base: ["SKIP_INSTALL": "YES"]),
    ),

    // ── Shared utilities ────────────────────────────────────────────────
    .target(
      name: "NimbCore",
      destinations: Nimb.destinations,
      product: .staticFramework,
      bundleId: "foxacid7cd.NimbCore",
      deploymentTargets: Nimb.deploymentTargets,
      infoPlist: .default,
      sources: ["Sources/NimbCore/**"],
      dependencies: [
        .macro(name: "NimbMacros"),
        .package(product: "Algorithms"),
        .package(product: "CasePaths"),
        .package(product: "Collections"),
        .package(product: "CustomDump"),
      ],
      settings: Nimb.settings(),
    ),

    // ── The app ─────────────────────────────────────────────────────────
    .target(
      name: "Nimb",
      destinations: Nimb.destinations,
      product: .app,
      productName: "Nimb",
      bundleId: "foxacid7cd.Nimb$(NIMB_BUNDLE_ID_SUFFIX)",
      deploymentTargets: Nimb.deploymentTargets,
      infoPlist: .dictionary([
        "CFBundleDevelopmentRegion": "$(DEVELOPMENT_LANGUAGE)",
        "CFBundleExecutable": "$(EXECUTABLE_NAME)",
        "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
        "CFBundleInfoDictionaryVersion": "6.0",
        "CFBundleName": "$(PRODUCT_NAME)",
        "CFBundleDisplayName": "Nimb",
        "CFBundlePackageType": "APPL",
        "CFBundleShortVersionString": "$(MARKETING_VERSION)",
        "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
        "LSMinimumSystemVersion": "$(MACOSX_DEPLOYMENT_TARGET)",
        "LSApplicationCategoryType": "public.app-category.developer-tools",
        "NSPrincipalClass": "NSApplication",
        "NSHumanReadableCopyright": "Copyright © 2022 foxacid7cd. All rights reserved.",
      ]),
      sources: .sourceFilesList(
        globs: [.glob("Nimb/Sources/**", excluding: ["Nimb/Sources/generated/**"])]
          + Nimb.generatedSources,
      ),
      resources: ["Nimb/Assets.xcassets"],
      scripts: [
        .post(
          path: "Scripts/copy-neovim-runtime.sh",
          name: "Copy Neovim Runtime",
          basedOnDependencyAnalysis: false,
          shellPath: "/bin/zsh",
        ),
      ],
      dependencies: [
        Nimb.msgpack,
        .target(name: "NimbCore"),
        .package(product: "Algorithms"),
        .package(product: "CasePaths"),
        .package(product: "Collections"),
        .package(product: "CustomDump"),
        // libswiftObjectiveC.tbd. `.swiftLibrary` already prefixes "swift",
        // so the name here must not repeat it.
        .sdk(name: "ObjectiveC", type: .swiftLibrary, status: .required),
      ],
      settings: Nimb.settings(
        base: [
          "MARKETING_VERSION": "0.0.1",
          "CURRENT_PROJECT_VERSION": "1",
          "SWIFT_OBJC_BRIDGING_HEADER": "Nimb/Sources/Nimb-Bridging-Header.h",
          "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
          "ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS": "NO",
          "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
          "CODE_SIGN_IDENTITY[sdk=macosx*]": "-",
          "SWIFT_EMIT_LOC_STRINGS": "YES",
          "SWIFT_ENABLE_EMIT_CONST_VALUES": "YES",
          "SWIFT_ENFORCE_EXCLUSIVE_ACCESS": "debug-only",
          "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/../Frameworks",
          // The app links libswiftObjectiveC.tbd out of the SDK's swift dir.
          "LIBRARY_SEARCH_PATHS": "$(inherited) $(SDKROOT)/usr/lib/swift",
          // Metal shaders are inline MSL strings compiled at runtime, so the
          // app needs no Metal build phase.
          "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
        ],
        debug: [
          "NIMB_BUNDLE_ID_SUFFIX": "Debug",
          "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon-Debug",
        ],
        release: [
          "NIMB_BUNDLE_ID_SUFFIX": "",
          "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon-Release",
        ],
      ),
    ),

    // ── Neovim API code generator ───────────────────────────────────────
    .target(
      name: "generate",
      destinations: Nimb.destinations,
      product: .commandLineTool,
      bundleId: "foxacid7cd.generate",
      deploymentTargets: Nimb.deploymentTargets,
      infoPlist: .default,
      sources: .sourceFilesList(globs: ["generate/**"]
        + Nimb.sharedMessagePack.map { SourceFileGlob.glob(.path($0)) }),
      dependencies: [
        Nimb.msgpack,
        .target(name: "NimbCore"),
        .package(product: "Algorithms"),
        .package(product: "ArgumentParser"),
        .package(product: "CasePaths"),
        .package(product: "Collections"),
        .package(product: "CustomDump"),
        .package(product: "SwiftSyntax"),
        .package(product: "SwiftSyntaxBuilder"),
      ],
      settings: Nimb.settings(base: [
        "SWIFT_OBJC_BRIDGING_HEADER": "generate/generate-Bridging-Header.h",
        "SKIP_INSTALL": "YES",
      ]),
    ),

    // ── msgpack stream inspector ────────────────────────────────────────
    .target(
      name: "msgpack-inspector",
      destinations: Nimb.destinations,
      product: .commandLineTool,
      bundleId: "foxacid7cd.msgpack-inspector",
      deploymentTargets: Nimb.deploymentTargets,
      infoPlist: .default,
      sources: ["msgpack-inspector/**"],
      dependencies: [
        Nimb.msgpack,
        .target(name: "NimbCore"),
        .package(product: "ArgumentParser"),
        .package(product: "CustomDump"),
      ],
      settings: Nimb.settings(base: ["SKIP_INSTALL": "YES"]),
    ),

    // ── decode throughput harness ───────────────────────────────────────
    .target(
      name: "speed-tuner",
      destinations: Nimb.destinations,
      product: .commandLineTool,
      bundleId: "foxacid7cd.speed-tuner",
      deploymentTargets: Nimb.deploymentTargets,
      infoPlist: .default,
      sources: .sourceFilesList(globs: ["speed-tuner/**"]
        + Nimb.sharedMessagePack.map { SourceFileGlob.glob(.path($0)) }),
      copyFiles: [
        .productsDirectory(
          name: "Copy speed-tuner assets",
          subpath: "speed-tuner-assets",
          files: ["speed-tuner/data.mpack"],
        ),
      ],
      dependencies: [
        Nimb.msgpack,
        .target(name: "NimbCore"),
        .package(product: "ArgumentParser"),
        .package(product: "CasePaths"),
        .package(product: "CustomDump"),
      ],
      settings: Nimb.settings(base: [
        "SWIFT_OBJC_BRIDGING_HEADER": "speed-tuner/speed-tuner-Bridging-Header.h",
        "CODE_SIGN_IDENTITY[sdk=macosx*]": "-",
        "SKIP_INSTALL": "YES",
      ]),
    ),
  ],
  schemes: [
    .scheme(
      name: "Nimb",
      shared: true,
      buildAction: .buildAction(targets: ["Nimb"]),
      runAction: .runAction(configuration: "Debug", executable: "Nimb"),
      archiveAction: .archiveAction(configuration: "Release"),
    ),
    .scheme(
      name: "generate",
      shared: true,
      buildAction: .buildAction(targets: ["generate"]),
      runAction: .runAction(configuration: "Debug", executable: "generate"),
    ),
  ],
)
