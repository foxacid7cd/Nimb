// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "libNims",
  products: [
    .library(
      name: "libNims",
      type: .static,
      targets: ["libNims"]
    )
  ],
  targets: [
    .target(
      name: "libNims",
      cSettings: [
        .unsafeFlags(["-fno-modules"]),
        .define("INCLUDE_GENERATED_DECLARATIONS", to: "1"),
        .headerSearchPath("../../src"),
        .headerSearchPath("../../build/include"),
        .headerSearchPath("../../.deps/usr/include"),
        .headerSearchPath("../../build/cmake.config"),
        .headerSearchPath("../../build/src/nvim/auto/")
      ],
      linkerSettings: [
        .linkedFramework("CoreServices"),
        .linkedFramework("CoreFoundation"),
        .linkedLibrary("util"),
        .linkedLibrary("m"),
        .linkedLibrary("dl"),
        .linkedLibrary("pthread"),
        .linkedLibrary("iconv"),
        .unsafeFlags([
          "Targets/libNims/build/lib/libnvim.a",
          "Targets/libNims/.deps/usr/lib/libmsgpackc.a",
          "Targets/libNims/.deps/usr/lib/libluv.a",
          "Targets/libNims/.deps/usr/lib/libuv_a.a",
          "Targets/libNims/.deps/usr/lib/libvterm.a",
          "Targets/libNims/.deps/usr/lib/libluajit-5.1.a",
          "Targets/libNims/.deps/usr/lib/libtree-sitter.a"
        ])
      ]
    )
  ],
  cLanguageStandard: .gnu11
)
