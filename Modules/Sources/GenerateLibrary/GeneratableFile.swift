// SPDX-License-Identifier: MIT

import SwiftSyntaxBuilder

public protocol GeneratableFile {
  init(_ metadata: Metadata)

  var name: String { get }
  var sourceFile: SourceFile { get }
}
