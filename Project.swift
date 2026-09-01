// SPDX-License-Identifier: MIT

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Nimb",
  organizationName: "foxacid7cd",
  options: .options(
    automaticSchemesOptions: .enabled(),
    disableBundleAccessors: true,
    // Xcode's own generated asset symbols are used instead, and Tuist's
    // accessors reference the Bundle.module that disableBundleAccessors removes.
    disableSynthesizedResourceAccessors: true,
  ),
  packages: [
    // Xcode's native SPM integration: Tuist's does not pass -package-name, so
    // packages using the `package` access level fail to build.
    .remote(url: "https://github.com/apple/swift-collections.git", requirement: .upToNextMajor(from: "1.6.0")),
    .remote(url: "https://github.com/apple/swift-algorithms.git", requirement: .upToNextMajor(from: "1.2.1")),
    .remote(url: "https://github.com/apple/swift-argument-parser.git", requirement: .upToNextMajor(from: "1.8.2")),
    .remote(url: "https://github.com/swiftlang/swift-syntax.git", requirement: .upToNextMajor(from: "603.0.2")),
    .remote(url: "https://github.com/pointfreeco/swift-custom-dump.git", requirement: .upToNextMajor(from: "1.7.0")),
  ],
  settings: .settings(
    base: ["SDKROOT": "macosx"],
    defaultSettings: .recommended,
  ),
  targets: [
    .target(
      name: "msgpack_c",
      destinations: Nimb.destinations,
      product: .staticLibrary,
      bundleId: "foxacid7cd.msgpack-c",
      deploymentTargets: Nimb.deploymentTargets,
      infoPlist: .default,
      sources: ["Third-Party/msgpack-c/src/**"],
      headers: .headers(public: [
        "Third-Party/msgpack-c-support/include/**",
        "Third-Party/msgpack-c/include/**",
      ]),
      settings: Nimb.settings(base: [
        "DEFINES_MODULE": "YES",
        "HEADER_SEARCH_PATHS": "$(SRCROOT)/Third-Party/msgpack-c-support/include/msgpack $(SRCROOT)/Third-Party/msgpack-c-support/include $(SRCROOT)/Third-Party/msgpack-c/include",
      ]),
    ),

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
        .target(name: "msgpack_c"),
        .package(product: "Algorithms"),
        .package(product: "Collections"),
        .package(product: "CustomDump"),
      ],
      settings: Nimb.settings(base: ["ENABLE_MODULE_VERIFIER": "YES"]),
    ),

    // ── Neovim RPC API and generated bindings ───────────────────────────
    .target(
      name: "NimbNeovim",
      destinations: Nimb.destinations,
      product: .staticFramework,
      bundleId: "foxacid7cd.NimbNeovim",
      deploymentTargets: Nimb.deploymentTargets,
      infoPlist: .default,
      sources: .sourceFilesList(
        globs: [.glob("Sources/NimbNeovim/*.swift")] + Nimb.generatedSources,
      ),
      scripts: [
        .pre(
          path: "Scripts/require-generated-sources.sh",
          name: "Require generated Neovim bindings",
          basedOnDependencyAnalysis: false,
          shellPath: "/bin/zsh",
        ),
      ],
      dependencies: [
        .target(name: "NimbCore"),
      ],
      settings: Nimb.settings(base: ["ENABLE_MODULE_VERIFIER": "YES"]),
    ),

    // ── Application state and reducers ──────────────────────────────────
    .target(
      name: "NimbState",
      destinations: Nimb.destinations,
      product: .staticFramework,
      bundleId: "foxacid7cd.NimbState",
      deploymentTargets: Nimb.deploymentTargets,
      infoPlist: .default,
      sources: ["Sources/NimbState/**"],
      dependencies: [
        .target(name: "NimbNeovim"),
        .package(product: "Algorithms"),
        .package(product: "Collections"),
        .package(product: "CustomDump"),
      ],
      settings: Nimb.settings(base: ["ENABLE_MODULE_VERIFIER": "YES"]),
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
        "CFBundleDocumentTypes": .array([
          .dictionary([
            "CFBundleTypeName": "Text Document",
            "CFBundleTypeRole": "Editor",
            "LSHandlerRank": "Alternate",
            "LSItemContentTypes": .array([
              "public.text",
              "public.plain-text",
              "public.source-code",
              "public.script",
              "public.shell-script",
              "public.xml",
              "public.json",
              "public.yaml",
              "net.daringfireball.markdown",
            ]),
          ]),
          // Any other file, the way a plain-text editor takes anything it is
          // handed, and directories, which Neovim opens with its file browser.
          .dictionary([
            "CFBundleTypeName": "Any File",
            "CFBundleTypeRole": "Editor",
            "LSHandlerRank": "Alternate",
            "LSItemContentTypes": .array([
              "public.data",
              "public.folder",
            ]),
          ]),
        ]),
        "NSHumanReadableCopyright": "Copyright © 2022 foxacid7cd. All rights reserved.",
      ]),
      sources: ["Nimb/Sources/**"],
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
        .target(name: "NimbState"),
        .target(name: "NimbNeovim"),
        .target(name: "NimbCore"),
        .package(product: "Algorithms"),
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
          "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
          "ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS": "NO",
          "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
          // Ad-hoc unless a local signing identity is passed in. Ad-hoc
          // rebuilds change the app's identity, so macOS re-asks for every
          // TCC permission; a stable certificate keeps the grants.
          "CODE_SIGN_IDENTITY[sdk=macosx*]": "$(NIMB_CODE_SIGN_IDENTITY:default=-)",
          // Manual, because automatic signing insists on a development team
          // the moment the identity is anything but ad-hoc.
          "CODE_SIGN_STYLE": "Manual",
          "PROVISIONING_PROFILE_SPECIFIER": "",
          "SWIFT_EMIT_LOC_STRINGS": "YES",
          "SWIFT_ENABLE_EMIT_CONST_VALUES": "YES",
          "SWIFT_ENFORCE_EXCLUSIVE_ACCESS": "debug-only",
          "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/../Frameworks",
          // The app links libswiftObjectiveC.tbd out of the SDK's swift dir.
          "LIBRARY_SEARCH_PATHS": "$(inherited) $(SDKROOT)/usr/lib/swift",
          // Metal shaders are inline MSL strings compiled at runtime, so the
          // app needs no Metal build phase.
          "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
          // View code only: the reducer and RPC layer live in modules that stay
          // nonisolated, and this setting is per-module.
          "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
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
      sources: ["generate/**"],
      dependencies: [
        .target(name: "NimbCore"),
        .package(product: "Algorithms"),
        .package(product: "ArgumentParser"),
        .package(product: "Collections"),
        .package(product: "CustomDump"),
        .package(product: "SwiftSyntax"),
        .package(product: "SwiftSyntaxBuilder"),
      ],
      settings: Nimb.settings(base: ["SKIP_INSTALL": "YES"]),
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
