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

  public var sourceFile: SourceFile {
    .init {
      "import Foundation" as ImportDecl

      EnumDecl("public enum References") {
        for type in metadata.types {
          StructDecl("public struct \(type.name): Sendable, Hashable") {
            "public var data: Data" as VariableDecl

            InitializerDecl("public init(data: Data)") {
              "self.data = data" as SequenceExprSyntax
            }

            InitializerDecl("public init?(type: Int8, data: Data)") {
              "guard type == Self.type else { return nil }" as GuardStmt

              "self.init(data: data)" as FunctionCallExpr
            }

            VariableDecl(
              """
              public static var type: Int8 {
                \(raw: type.id.rawValue)
              }
              """
            )

            VariableDecl(
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
