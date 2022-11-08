// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "libNims",
  products: [
    .library(
      name: "libNims",
      targets: ["libNims"]
    )
  ],
  targets: [
    .target(
      name: "libNims",
      cSettings: [
        .unsafeFlags(["-fno-modules"]),
        .define("INCLUDE_GENERATED_DECLARATIONS", to: "1"),
        .headerSearchPath("src"),
        .headerSearchPath("build/include"),
        .headerSearchPath(".deps/usr/include"),
        .headerSearchPath("build/cmake.config"),
        .headerSearchPath("build/src/nvim/auto/")
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
          "build/lib/libnvim.a",
          ".deps/usr/lib/libmsgpackc.a",
          ".deps/usr/lib/libluv.a",
          ".deps/usr/lib/libuv_a.a",
          ".deps/usr/lib/libvterm.a",
          ".deps/usr/lib/libluajit-5.1.a",
          ".deps/usr/lib/libtree-sitter.a"
        ])
      ]
    )
  ],
  cLanguageStandard: .gnu11
)
