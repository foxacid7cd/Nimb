// SPDX-License-Identifier: MIT

import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

public struct APIFunctionsFile: GeneratableFile {
  public init(metadata: Metadata) { self.metadata = metadata }

  public var metadata: Metadata

  public var name: String { "APIFunctions" }

  public var sourceFile: SourceFile {
    .init {
      "import CasePaths" as ImportDecl
      "import MessagePack" as ImportDecl

      ExtensionDecl(modifiers: [.init(name: .public)], extendedType: "API" as Type) {
        for function in metadata.functions {
          let parametersInSignature = function.parameters
            .map {
              "\($0.name.camelCasedAssumingSnakeCased(capitalized: false)): \($0.type.swift.signature)"
            }
            .joined(separator: ", ")

          let functionNameInSignature = function.name.camelCasedAssumingSnakeCased(
            capitalized: false
          )
          FunctionDecl(
            "func \(functionNameInSignature)(\(parametersInSignature)) async throws -> Result<\(function.returnType.swift.signature), RemoteError>"
          ) {
            let parametersInArray = function.parameters
              .map { parameter in
                let name = parameter.name.camelCasedAssumingSnakeCased(capitalized: false)

                return parameter.type.wrapWithValueEncoder(String(name))
              }
              .joined(separator: ", ")
            "return try await call(method: \(literal: function.name), withParameters: [\(raw: parametersInArray)], transformSuccess: { \(raw: function.returnType.wrapWithValueDecoder("$0")) })"
              as Stmt
          }
          .withUnexpectedBeforeAttributes(
            .init {
              if function.deprecatedSince != nil {
                StringSegment(content: "@available(*, deprecated) ")
              }
            }
          )
        }
      }
    }
  }
}
