// SPDX-License-Identifier: MIT

import Algorithms
import CasePaths
import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

public struct UIOptionFile: GeneratableFile {
  public init(metadata: Metadata) {
    self.metadata = metadata
  }

  public var metadata: Metadata

  public var name: String {
    "UIOption"
  }

  public var sourceFile: SourceFileSyntax {
    get throws {
      try .init {
        try .init {
          try EnumDeclSyntax("public enum UIOption: String") {
            for uiOption in metadata.uiOptions {
              let camelCased = uiOption.camelCasedAssumingSnakeCased(capitalized: false)
              "case \(raw: camelCased) = \(literal: uiOption)" as DeclSyntax
            }
          }
        }
      }
    }
  }
}
