// SPDX-License-Identifier: MIT

import SwiftSyntaxBuilder

public protocol GeneratableFile {
  init(metadata: Metadata)

  var name: String { get }
  var sourceFile: SourceFile { get }
}
