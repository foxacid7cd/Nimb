// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "nvim",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "nvim", targets: ["nvim"]),
  ],
  targets: [
    .executableTarget(
      name: "nvim",
      dependencies: [],
      linkerSettings: [
        .linkedFramework("CoreServices"),
        .linkedLibrary("iconv"),
        .unsafeFlags([
          "-L/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Third-Party/neovim/.deps/usr/lib",
          "-lluajit-5.1",
          "-lluv",
          "-lmsgpackc",
          "-ltermkey",
          "-ltree-sitter",
          "-lunibilium",
          "-luv_a",
          "-lvterm",
          "-L/opt/homebrew/lib",
          "-lintl",
          "-L/Users/foxacid/ghq/github.com/foxacid7cd/Nims/Third-Party/neovim/build/lib",
          "-lnvim",
        ]),
      ]
    ),
  ]
)
