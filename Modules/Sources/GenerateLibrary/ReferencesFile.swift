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
        "import Foundation" as DeclSyntax
        "import Tagged" as DeclSyntax

        try EnumDeclSyntax("public enum References") {
          for type in metadata.types {
            try EnumDeclSyntax("public enum \(raw: type.name)Tag") {}
            "public typealias \(raw: type.name) = Tagged<\(raw: type.name)Tag, Int>\n" as DeclSyntax
          }
        }

        for type in metadata.types {
          try ExtensionDeclSyntax("public extension References.\(raw: type.name)") {
            try InitializerDeclSyntax("init?(type: Int8, data: Data)") {
              "guard type == References.\(raw: type.name).type else { return nil }" as StmtSyntax

              "self = .init(Int(data.externalReferenceID))" as ExprSyntax
            }

            try VariableDeclSyntax("static var type: Int8") {
              StmtSyntax(
                "return \(raw: type.id.rawValue)"
              )
            }
          }
        }
      }
    }
  }
}
