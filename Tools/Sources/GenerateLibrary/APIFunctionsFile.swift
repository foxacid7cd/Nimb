// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

public struct APIFunctionsFile: GeneratableFile {
  public init(_ metadata: Metadata) {
    self.metadata = metadata
  }

  public var metadata: Metadata

  public var name: String {
    "APIFunctions"
  }

  public var sourceFile: SourceFile {
    .init {
      "import MessagePack" as ImportDecl

      ExtensionDecl(modifiers: [.init(name: .public)], extendedType: "API" as Type) {
        for function in metadata.functions {
          let parametersInSignature = function.parameters
            .map {
              "\($0.name.camelCasedAssumingSnakeCased(capitalized: false)): \(APIType($0.type).inSignature)"
            }
            .joined(separator: ", ")

          let returnTypeInSignature = APIType(function.returnType).inSignature

          let functionNameInSignature = function.name
            .camelCasedAssumingSnakeCased(capitalized: false)
          FunctionDecl(
            "func \(functionNameInSignature)(\(parametersInSignature)) async throws -> Result<\(returnTypeInSignature), RemoteError>"
          ) {
            let parametersInArray = function.parameters
              .map { $0.name.camelCasedAssumingSnakeCased(capitalized: false) }
              .joined(separator: ", ")
            "return try await call(method: \"\(function.name)\", withParameters: [\(parametersInArray)], assumingSuccessType: \(returnTypeInSignature).self)" as Stmt
          }
          .withUnexpectedBeforeAttributes(.init {
            if function.deprecatedSince != nil {
              StringSegment(content: "@available(*, deprecated) ")
            }
          })
        }
      }
    }
  }
}