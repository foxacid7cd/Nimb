// SPDX-License-Identifier: MIT

import SwiftSyntax
import SwiftSyntaxBuilder

public struct ReferencesFile: GeneratableFile {
  public init(metadata: Metadata) {
    self.metadata = metadata
  }

  public var metadata: Metadata

  public var name: String {
    "References"
  }

  public var sourceFile: SourceFileSyntax {
    get throws {
      try .init {
        ImportDeclSyntax(path: [.init(name: "Foundation")])

        try EnumDeclSyntax("public enum References") {
          for type in metadata.types {
            try StructDeclSyntax("public struct \(raw: type.name): Sendable, Hashable") {
              "public var data: Data" as DeclSyntax

              try InitializerDeclSyntax("public init(data: Data)") {
                "self.data = data" as ExprSyntax
              }

              try InitializerDeclSyntax("public init?(type: Int8, data: Data)") {
                "guard type == Self.type else { return nil }" as StmtSyntax

                "self.init(data: data)" as ExprSyntax
              }

              DeclSyntax(
                """
                public static var type: Int8 {
                  \(raw: type.id.rawValue)
                }
                """
              )

              DeclSyntax(
                """
                public static var prefix: String {
                  \(literal: type.prefix)
                }
                """
              )
            }
          }
        }
      }
    }
  }
}
