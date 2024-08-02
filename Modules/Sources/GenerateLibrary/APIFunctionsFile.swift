// SPDX-License-Identifier: MIT

import CasePaths
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
        "import Library" as DeclSyntax

        try EnumDeclSyntax("public enum APIFunctions") {
          for function in metadata.functions {
            let camelCasedFunctionName = function.name
              .camelCasedAssumingSnakeCased(capitalized: true)

            try StructDeclSyntax(
              """
              \(raw: function.deprecationAttributeIfNeeded)
              @PublicInit
              public struct \(raw: camelCasedFunctionName): APIFunction
              """
            ) {
              DeclSyntax(
                "public static let method = \(literal: function.name)"
              )

              for parameter in function.parameters {
                let camelCasedParameterName = parameter.name
                  .camelCasedAssumingSnakeCased(capitalized: false)

                DeclSyntax(
                  "public var \(raw: camelCasedParameterName): \(raw: parameter.type.swift.signature)"
                )
              }

              let parametersInArray = function.parameters
                .map { parameter in
                  let name = parameter.name.camelCasedAssumingSnakeCased(capitalized: false)

                  return parameter.type.wrapWithValueEncoder(String(name))
                }
                .joined(separator: ", ")

              try VariableDeclSyntax("public var parameters: [Value]") {
                StmtSyntax(
                  "return [\(raw: parametersInArray)]"
                )
              }

              if function.returnType.swift[case: \.value] == nil {
                try FunctionDeclSyntax(
                  "public static func decodeSuccess(from raw: Value) throws -> \(raw: function.returnType.swift.signature)"
                ) {
                  StmtSyntax(
                    """
                    guard \(raw: function.returnType.wrapWithValueDecoder(
                      "raw",
                      name: "value"
                    )) else {
                      throw Failure("failed decoding success return value", raw)
                    }
                    """
                  )
                  StmtSyntax(
                    "return value"
                  )
                }
              }
            }
          }
        }

        try ExtensionDeclSyntax("public extension API") {
          for function in metadata.functions {
            let parametersInSignature = function.parameters
              .map {
                let name = $0.name.camelCasedAssumingSnakeCased(capitalized: false)
                return "\(name): \($0.type.swift.signature)"
              }
              .joined(separator: ", ")
            let initializingWithParameters = function.parameters
              .map {
                let name = $0.name.camelCasedAssumingSnakeCased(capitalized: false)
                return "\(name): \(name)"
              }
              .joined(separator: ", ")
            let camelCasedFunctionName = function.name
              .camelCasedAssumingSnakeCased(capitalized: false)
            let capitalizedCamelCasedFunctionName = function.name
              .camelCasedAssumingSnakeCased(capitalized: true)
            try FunctionDeclSyntax(
              """
              \(raw: function.deprecationAttributeIfNeeded)
              @discardableResult
              func \(raw: camelCasedFunctionName)(\(raw: parametersInSignature)) async throws -> \(
                raw: function
                  .returnType.swift.signature
              )
              """
            ) {
              ExprSyntax(
                "try await call(APIFunctions.\(raw: capitalizedCamelCasedFunctionName)(\(raw: initializingWithParameters)))"
              )
            }
          }
        }
      }
    }
  }
}
