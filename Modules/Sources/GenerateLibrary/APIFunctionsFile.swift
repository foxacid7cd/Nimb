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
        "import Tagged" as DeclSyntax

        try ExtensionDeclSyntax("public extension API") {
          let validFunctions = metadata.functions
            .filter { $0.deprecatedSince == nil }

          for function in validFunctions {
            let parametersInSignature = function.parameters
              .map {
                let name = $0.name.camelCasedAssumingSnakeCased(capitalized: false)
                return "\(name): \($0.type.swift.signature)"
              }
              .joined(separator: ", ")

            let functionNameInSignature = function.name
              .camelCasedAssumingSnakeCased(capitalized: false)
            try FunctionDeclSyntax(
              "func \(raw: functionNameInSignature)(\(raw: parametersInSignature)) async throws -> RPC<Target>.Response.Result"
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
                """
              )
              //.map { \(raw: function.returnType.wrapWithValueDecoder("$0", force: true)) }
            }

            let fastFunctionNameInSignature = functionNameInSignature + "Fast"
            try FunctionDeclSyntax(
              "func \(raw: fastFunctionNameInSignature)(\(raw: parametersInSignature)) async throws"
            ) {
              let parametersInArray = function.parameters
                .map { parameter in
                  let name = parameter.name.camelCasedAssumingSnakeCased(capitalized: false)

                  return parameter.type.wrapWithValueEncoder(String(name))
                }
                .joined(separator: ",\n")

              ExprSyntax(
                """
                try await rpc.fastCall(
                  method: \(literal: function.name),
                  withParameters: [
                    \(raw: parametersInArray)
                  ]
                )
                """
              )
            }
          }
        }
      }
    }
  }
}
