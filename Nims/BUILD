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

cc_import(
  name = "libvterm",
  hdrs = [],
  static_library = "libvterm.a"
)

cc_import(
  name = "libuv_a",
  hdrs = [],
  static_library = "libuv_a.a"
)

cc_import(
  name = "libunibilium",
  hdrs = [],
  static_library = "libunibilium.a"
)

cc_import(
  name = "libtree-sitter",
  hdrs = [],
  static_library = "libtree-sitter.a"
)

cc_import(
  name = "libtermkey",
  hdrs = [],
  static_library = "libtermkey.a"
)

cc_import(
  name = "libmsgpackc",
  hdrs = [],
  static_library = "libmsgpackc.a"
)

cc_import(
  name = "libluv",
  hdrs = [],
  static_library = "libluv.a"
)

cc_import(
  name = "libluajit-5.1",
  hdrs = [],
  static_library = "libluajit-5.1.a"
)

cc_import(
  name = "libintl",
  hdrs = [],
  static_library = "libintl.a"
)

objc_library(
  name = "libiconv",
  sdk_dylibs = ["libiconv"],
)

cc_import(
  name = "libnvim",
  static_library = "libnvim.a"
)

swift_library(
  name = "NvimServiceAPI",
  srcs = glob([
    "Modules/NvimServiceAPI/Sources/**/*.swift"
  ]),
  module_name = "NvimServiceAPI"
)

swift_library(
  name = "_NvimService",
  srcs = glob([
    "Modules/NvimService/Sources/**/*.swift"
  ]),
  copts = [
    "-import-objc-header",
    "Nims/Modules/NvimService/Sources/Bridging-Header.h",
  ],
  deps = [":libvterm", ":libuv_a", ":libunibilium", ":libtree-sitter", ":libtermkey", ":libmsgpackc", ":libluv", ":libluajit-5.1", ":libintl", ":libiconv", ":libnvim", ":NvimServiceAPI"],
)

swift_library(
  name = "_Nims",
  srcs = glob([
    "Sources/**/*.swift",
  ]),
  copts = [
    "-import-objc-header",
    "Nims/Sources/Bridging-Header.h",
  ],
  deps = [
    ":NvimServiceAPI"
  ],
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
