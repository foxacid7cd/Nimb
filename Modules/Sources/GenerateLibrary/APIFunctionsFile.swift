// SPDX-License-Identifier: MIT

import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

public struct APIFunctionsFile: GeneratableFile {
  public init(metadata: Metadata) { self.metadata = metadata }

  public var metadata: Metadata

  public var name: String { "APIFunctions" }

  public var sourceFile: SourceFileSyntax {
    get throws {
      try .init {
        "import CasePaths" as DeclSyntax
        "import MessagePack" as DeclSyntax

        try ExtensionDeclSyntax("public extension API") {
          for function in metadata.functions {
            let parametersInSignature = function.parameters
              .map {
                "\($0.name.camelCasedAssumingSnakeCased(capitalized: false)): \($0.type.swift.signature)"
              }
              .joined(separator: ", ")

            let functionNameInSignature = function.name.camelCasedAssumingSnakeCased(
              capitalized: false
            )
            try FunctionDeclSyntax(
              /* "\(raw: function.deprecatedSince != nil ? "@available(*, deprecated" : "") */ "func \(raw: functionNameInSignature)(\(raw: parametersInSignature)) async throws -> Result<\(raw: function.returnType.swift.signature), RemoteError>"
            ) {
              let parametersInArray = function.parameters
                .map { parameter in
                  let name = parameter.name.camelCasedAssumingSnakeCased(capitalized: false)

                  return parameter.type.wrapWithValueEncoder(String(name))
                }
                .joined(separator: ",\n")

              StmtSyntax(
                """
                return try await rpc.call(
                  method: \(literal: function.name),
                  withParameters: [
                    \(raw: parametersInArray)
                  ]
                )
                .map { \(raw: function.returnType.wrapWithValueDecoder("$0", force: true)) }
                """
              )
            }
          }
        }
      }
    }
  }
}
