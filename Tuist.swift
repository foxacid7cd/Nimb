// SPDX-License-Identifier: MIT

import ProjectDescription

let tuist = Tuist(
  project: .tuist(
    compatibleXcodeVersions: .upToNextMajor("26.0"),
    generationOptions: .options(
      // Left at the default "5". Raising it would push every external SPM
      // target into the Swift 6 language mode, which they are not ready for.
      // Our own targets set SWIFT_VERSION = 6.0 explicitly.
      defaultConfiguration: "Debug",
    ),
  ),
)
