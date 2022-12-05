// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

struct APIFunctionsFile: GeneratableFile {
  var metadata: NeovimAPIMetadata

  var name: String { "\(Self.self)" }

  var sourceFile: SourceFile {
    .init {
      ExtensionDecl(extendedType: "API" as Type) {
        for function in metadata.functions {
          let parametersInSignature = function.parameters
            .map { "\($0.name.camelCased): Value" }
            .joined(separator: ", ")

          FunctionDecl(
            "func \(function.name.camelCased)(\(parametersInSignature)) async throws -> Response"
          ) {
            let parametersInArray = function.parameters
              .map(\.name.camelCased)
              .joined(separator: ", ")

            "return try await rpc.call(method: \"\(function.name)\", parameters: [\(parametersInArray)])" as Stmt
          }
          .withUnexpectedBeforeAttributes(.init {
            if function.deprecatedSince != nil {
              StringSegment(content: "@available(*, deprecated) ")
            }

            StringSegment(content: "@discardableResult ")
          })
        }
      }
    }
  }
}
