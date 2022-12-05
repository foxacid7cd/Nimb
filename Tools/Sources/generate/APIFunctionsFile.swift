// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation
import NvimAPI
import SwiftSyntax
import SwiftSyntaxBuilder

struct APIFunctionsFile: GeneratableFile {
  var metadata: NeovimAPIMetadata

  var name: String { "\(Self.self)" }

  var sourceFile: SourceFile {
    .init {
      ExtensionDecl(modifiers: [.init(name: .public)], extendedType: "API" as Type) {
        for function in metadata.functions {
          let parametersInSignature = function.parameters
            .map { "\($0.name.camelCased): \(APIType($0.type).inSignature)" }
            .joined(separator: ", ")

          let returnTypeInSignature = APIType(function.returnType).inSignature

          FunctionDecl(
            "func \(function.name.camelCased)(\(parametersInSignature)) async throws -> Result<\(returnTypeInSignature), NeovimError>"
          ) {
            let parametersInArray = function.parameters
              .map(\.name.camelCased)
              .joined(separator: ", ")

            "return try await rpc.call(method: \"\(function.name)\", parameters: [\(parametersInArray)]).resultAssuming(successType: \(returnTypeInSignature).self)" as Stmt
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

private let mapTypes: Set = ["Object", "Dictionary"]

private let integerTypes: Set = ["Buffer", "Integer", "LuaRef", "Tabpage", "Window"]

private enum APIType {
  case integer
  case float
  case string
  case boolean
  case map
  case array
  case value

  init(_ rawValue: String) {
    if rawValue.starts(with: "Array") {
      self = .array

    } else if mapTypes.contains(rawValue) {
      self = .map

    } else if integerTypes.contains(rawValue) {
      self = .integer

    } else if rawValue == "Float" {
      self = .float

    } else if rawValue == "String" {
      self = .string

    } else if rawValue == "Boolean" {
      self = .boolean

    } else {
      self = .value
    }
  }

  var inSignature: String {
    switch self {
    case .integer:
      return "Int"

    case .float:
      return "Double"

    case .string:
      return "String"

    case .boolean:
      return "Bool"

    case .map:
      return "Map"

    case .array:
      return "[Value]"

    case .value:
      return "Value"
    }
  }
}
