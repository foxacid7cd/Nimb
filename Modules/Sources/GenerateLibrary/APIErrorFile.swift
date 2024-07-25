// SPDX-License-Identifier: MIT

import CasePaths
import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

public struct APIErrorFile: GeneratableFile {
  public init(metadata: Metadata) { self.metadata = metadata }

  public var metadata: Metadata

  public var name: String { "APIError" }

  public var sourceFile: SourceFileSyntax {
    get throws {
      try .init {
        "import CasePaths" as DeclSyntax

        try EnumDeclSyntax(
          """
          @CasePathable
          @dynamicMemberLookup
          public enum APIError: Int, Sendable, Hashable
          """
        ) {
          for errorType in metadata.errorTypes {
            let camelCasedTypeName = errorType.name.camelCasedAssumingSnakeCased(capitalized: false)
            DeclSyntax(
              """
              case \(raw: camelCasedTypeName) = \(literal: errorType.id)
              """
            )
          }
        }
      }
    }
  }
}
