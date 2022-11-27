BRIDGING_HEADER = "Nims/Sources/Nims-Bridging-Header.h"

load("@build_bazel_rules_swift//swift:swift.bzl", 
     "swift_library"
)

load("@build_bazel_rules_apple//apple:macos.bzl",
     "macos_application",
     "macos_xpc_service",
)

load("@build_bazel_rules_apple//apple:versioning.bzl",
    "apple_bundle_version",
)

swift_library(
  name = "NvimServiceAPI",
  srcs = glob([
    "Modules/NvimServiceAPI/Sources/**/*.swift"
  ])
)

swift_library(
  name = "_NvimService",
  srcs = glob([
    "Modules/NvimService/Sources/**/*.swift"
  ]),
  deps = [":NvimServiceAPI"],
)

swift_library(
  name = "_Nims",
  srcs = glob([
    "Sources/**/*.swift",
  ]),
  copts = [
    "-import-objc-header",
    BRIDGING_HEADER,
  ],
  deps = [":NvimServiceAPI"],
)

apple_bundle_version(
  name = "NimsVersion",
  build_version = "1.0.0",
)

macos_xpc_service(
  name = "NvimService",
  bundle_id = "foxacid7cd.Nims.NvimService",
  infoplists = ["Modules/NvimService/Info.plist"],
  minimum_os_version = "13.0",
  version = ":NimsVersion",
  deps = [":_NvimService"],
)

macos_application(
  name = "Nims",
  bundle_id = "foxacid7cd.Nims",
  infoplists = ["Info.plist"],
  minimum_os_version = "13.0",
  version = ":NimsVersion",
  xpc_services = [":NvimService"],
  deps = [":_Nims"]
)
