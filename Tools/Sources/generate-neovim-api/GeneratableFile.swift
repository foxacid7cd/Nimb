// Copyright © 2022 foxacid7cd. All rights reserved.

import SwiftSyntaxBuilder

protocol GeneratableFile {
  var name: String { get }
  var sourceFile: SourceFile { get }
}
