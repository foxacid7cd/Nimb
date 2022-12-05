// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

public struct APIFunctionsFile: Generatable {
  public init(metadata: Metadata) {
    self.metadata = metadata
  }

  public var metadata: Metadata

  public var fileName: String {
    "APIFunctions"
  }

  public var statements: CodeBlockItemList {
    "import MessagePack" as ImportDecl

    ExtensionDecl(modifiers: [.init(name: .public)], extendedType: "API" as Type) {
      for function in metadata.functions {
        let parametersInSignature = function.parameters
          .map { "\($0.name.camelCased): \(APIType($0.type).inSignature)" }
          .joined(separator: ", ")

        let returnTypeInSignature = APIType(function.returnType).inSignature

        FunctionDecl(
          "func \(function.name.camelCased)(\(parametersInSignature)) async throws -> Result<\(returnTypeInSignature), RemoteError>"
        ) {
          let parametersInArray = function.parameters
            .map(\.name.camelCased)
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

private let MapTypes: Set = ["Object", "Dictionary"]
private let IntegerTypes: Set = ["Buffer", "Integer", "LuaRef", "Tabpage", "Window"]

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

    } else if MapTypes.contains(rawValue) {
      self = .map

    } else if IntegerTypes.contains(rawValue) {
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
      return "MessageMapValue"

    case .array:
      return "[MessageValue]"

    case .value:
      return "MessageValue"
    }
  }
}
