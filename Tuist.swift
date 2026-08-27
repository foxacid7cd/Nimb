// SPDX-License-Identifier: MIT

import ProjectDescription

let tuist = Tuist(
  project: .tuist(
    compatibleXcodeVersions: .upToNextMajor("26.0"),
    generationOptions: .options(
      // Left at the default "5", which would otherwise push external SPM
      // targets into Swift 6. Our own targets set SWIFT_VERSION explicitly.
      defaultConfiguration: "Debug",
    ),
  ),
)
