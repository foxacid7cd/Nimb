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
              "public var \(formattedName): \(parameter.type.swift.signature)" as VariableDecl
            }
          }
        }
      }

      EnumDecl("public enum UIEventBatch") {
        for uiEvent in metadata.uiEvents {
          let caseName = uiEvent.name
            .camelCasedAssumingSnakeCased(capitalized: false)

          let structName = uiEvent.name
            .camelCasedAssumingSnakeCased(capitalized: true)

          EnumCaseDecl("case \(caseName)(LazyMapSequence<[Value], UIEvents.\(structName)>)")
        }

        InitializerDecl("init(_ value: Value)") {
          Stmt("""
          guard case var .array(arrayValue) = value else {
            fatalError("Failed decoding UI event, root value is not array")
          }
          """)

          Stmt("""
          guard !arrayValue.isEmpty, case let .string(name) = arrayValue.removeFirst() else {
            fatalError("Failed decoding UI event name.")
          }
          """)

          SwitchStmt(
            switchKeyword: .switch,
            expression: "name" as IdentifierExpr,
            leftBrace: .leftBrace,
            cases: .init {
              SwitchCaseList {
                for uiEvent in metadata.uiEvents {
                  SwitchCase("case \"\(uiEvent.name)\":") {
                    let caseName = uiEvent.name.camelCasedAssumingSnakeCased(capitalized: false)
                    let structName = uiEvent.name.camelCasedAssumingSnakeCased(capitalized: true)

                    let transformExpr = ClosureExpr(
                      signature: ClosureSignature(
                        leadingTrivia: .space,
                        input: .input(
                          .init(
                            parameterList: [
                              .init(
                                firstName: .init(.identifier("value"), presence: .present),
                                colon: .colon,
                                type: "Value" as Type
                              ),
                            ]
                          )
                        ),
                        output: .init(
                          returnType: "UIEvents.\(structName) " as Type
                        )
                      ),
                      statements: .init {
                        Stmt("""
                        guard case let .array(arrayValue) = value else {
                          fatalError("Failed decoding (UIEvents.\(structName)), value is not array.")
                        }
                        """)

                        let parametersCountCondition =
                          "arrayValue.count == \(uiEvent.parameters.count)"
                        let parameterTypeConditions = uiEvent.parameters
                          .enumerated()
                          .map { index, parameter -> String in
                            let name = parameter.name
                              .camelCasedAssumingSnakeCased(capitalized: false)

                            let wrappedName = parameter.type
                              .wrapExprWithValueEncoder(String(name))

                            return "case let \(wrappedName) = arrayValue[\(index)]"
                          }
                        let guardConditions = ([parametersCountCondition] + parameterTypeConditions)
                          .joined(separator: ", ")
                        Stmt("""
                        guard \(guardConditions) else {
                          fatalError("Failed decoding (UIEvents.\(structName)), invalid parameters.")
                        }
                        """)

                        let structArguments = uiEvent.parameters
                          .map { parameter in
                            let name = parameter.name
                              .camelCasedAssumingSnakeCased(capitalized: false)
                            return "\(name): \(name)"
                          }
                          .joined(separator: ", ")
                        Stmt("""
                        return .init(\(structArguments))
                        """)
                      }
                    )
                    VariableDecl(.let, name: "transform", initializer: .init(value: transformExpr))
                    "self = .\(caseName)(arrayValue.lazy.map(transform))" as Expr
                  }
                }

                SwitchCase("default:") {
                  Expr("""
                  fatalError("Failed decoding UI event, unknown name " + name)
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
