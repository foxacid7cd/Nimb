// Copyright © 2022 foxacid7cd. All rights reserved.

import SwiftSyntaxBuilder

public protocol GeneratableFile {
  init(_ metadata: Metadata)

  var name: String { get }
  var sourceFile: SourceFile { get }
}
