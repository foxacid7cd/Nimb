// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

public struct UIEventsFile: GeneratableFile {
  public init(_ metadata: Metadata) {
    self.metadata = metadata
  }

  public var metadata: Metadata

  public var name: String {
    "UIEvents"
  }

  public var sourceFile: SourceFile {
    .init {
      "import MessagePack" as ImportDecl
      "import CasePaths" as ImportDecl

      EnumDecl("public enum UIEvents") {
        for uiEvent in metadata.uiEvents {
          let structName = uiEvent.name
            .camelCasedAssumingSnakeCased(capitalized: true)

          StructDecl(
            "public struct \(structName)"
          ) {
            for parameter in uiEvent.parameters {
              let formattedName = parameter.name.camelCasedAssumingSnakeCased(capitalized: false)
              "public var \(raw: formattedName): \(raw: parameter.type.swift.signature)" as VariableDecl
            }
          }
        }
      }

      EnumDecl("public enum UIEventBatch") {
        Decl("""
        public enum DecodingFailed: Error {
          case initial(rawEventBatch: Value, details: String)
          case event(name: String, rawEvent: Value, details: String)
        }
        """)

        for uiEvent in metadata.uiEvents {
          let caseName = uiEvent.name
            .camelCasedAssumingSnakeCased(capitalized: false)

          let structName = uiEvent.name
            .camelCasedAssumingSnakeCased(capitalized: true)

          EnumCaseDecl("case \(raw: caseName)(@Sendable () throws -> [UIEvents.\(raw: structName)])")
        }

        InitializerDecl("init(_ value: Value) throws") {
          Stmt("""
          guard case let .array(arrayValue) = value else {
            throw DecodingFailed.initial(rawEventBatch: value, details: "Raw value is not an array")
          }
          """)

          Stmt("""
          guard case let .string(name) = arrayValue.first else {
            throw DecodingFailed.initial(rawEventBatch: value, details: "First array value element is not a name string or array is empty")
          }
          """)

          SwitchStmt(
            switchKeyword: .switch,
            expression: "name" as IdentifierExpr,
            leftBrace: .leftBrace,
            cases: .init {
              SwitchCaseList {
                for uiEvent in metadata.uiEvents {
                  SwitchCase("case \"\(raw: uiEvent.name)\":") {
                    let caseName = uiEvent.name.camelCasedAssumingSnakeCased(capitalized: false)
                    let structName = uiEvent.name.camelCasedAssumingSnakeCased(capitalized: true)

                    let decodeClosureExpr = ClosureExpr(
                      signature: ClosureSignature(
                        leadingTrivia: .space,
                        attributes: [.attribute(.init(attributeName: .identifier("Sendable")))],
                        input: .input(.init()),
                        throwsTok: .throwsKeyword(leadingTrivia: .space),
                        output: .init(
                          returnType: "[UIEvents.\(raw: structName)] " as Type
                        )
                      ),
                      statements: .init {
                        VariableDecl("""
                        var accumulator = [UIEvents.\(raw: structName)]()
                        """)
                        ForInStmt("for rawEvent in arrayValue.dropFirst()") {
                          Stmt("""
                          guard case let .array(rawParameters) = rawEvent else {
                            throw DecodingFailed.event(name: \(
                              literal: uiEvent
                                .name
                          ), rawEvent: rawEvent, details: "Raw value is not a parameters array.")
                          }
                          """)

                          let parametersCountCondition =
                            "rawParameters.count == \(uiEvent.parameters.count)"
                          let parameterTypeConditions = uiEvent.parameters
                            .enumerated()
                            .map { index, parameter -> String in
                              let name = parameter.name
                                .camelCasedAssumingSnakeCased(capitalized: false)

                              let wrappedName = parameter.type
                                .wrapWithValueEncoder(String(name))

                              return "case let \(wrappedName) = rawParameters[\(index)]"
                            }
                          let guardConditions = ([parametersCountCondition] + parameterTypeConditions)
                            .joined(separator: ", ")
                          Stmt("""
                          guard \(raw: guardConditions) else {
                            throw DecodingFailed.event(name: \(
                              literal: uiEvent
                                .name
                          ), rawEvent: rawEvent, details: "Invalid parameters count or type of individual parameter.")
                          }
                          """)

                          let structArguments = uiEvent.parameters
                            .map { parameter in
                              let name = parameter.name
                                .camelCasedAssumingSnakeCased(capitalized: false)
                              return "\(name): \(name)"
                            }
                            .joined(separator: ", ")
                          Expr("""
                          accumulator.append(
                            .init(\(raw: structArguments))
                          )
                          """)
                        }
                        Stmt("""
                        return accumulator
                        """)
                      }
                    )
                    VariableDecl(.let, name: "decode", initializer: .init(value: decodeClosureExpr))
                    "self = .\(raw: caseName)(decode)" as Expr
                  }
                }

                SwitchCase("default:") {
                  Stmt("""
                  throw DecodingFailed.initial(rawEventBatch: value, details: "Unknown name " + name)
                  """)
                }
              }
            },
            rightBrace: .rightBrace
          )
        }
      }
    }
  }
}
