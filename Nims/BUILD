load("@build_bazel_rules_swift//swift:swift.bzl", 
     "swift_library"
)

load("@build_bazel_rules_apple//apple:macos.bzl",
     "macos_application"
)

swift_library(
  name = "Library",
  srcs = glob([
    "Sources/**/*.swift",
  ])
)

macos_application(
  name = "Nims",
  bundle_id = "foxacid7cd.Nims",
  infoplists = [
    ":Info.plist"
  ],
  minimum_os_version = "13.0.1",
  deps = [":Library"]
)
