// SPDX-License-Identifier: MIT

import SwiftSyntax

public protocol GeneratableFile {
  init(metadata: Metadata)

  var name: String { get }
  var sourceFile: SourceFileSyntax { get throws }
}
