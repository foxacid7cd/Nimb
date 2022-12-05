// Copyright © 2022 foxacid7cd. All rights reserved.

import SwiftSyntaxBuilder

protocol Generatable {
  var fileName: String { get }

  @CodeBlockItemListBuilder
  var statements: CodeBlockItemList { get }
}
