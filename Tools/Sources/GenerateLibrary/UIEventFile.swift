// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

public struct UIEventFile: GeneratableFile {
  public init(_ metadata: Metadata) {
    self.metadata = metadata
  }

  public var metadata: Metadata

  public var name: String {
    "UIEvent"
  }

  public var sourceFile: SourceFile {
    .init {
      "import MessagePack" as ImportDecl
      "import CasePaths" as ImportDecl

      EnumDecl("public enum UIEvent") {
        InitializerDecl("init(_ value: Value) throws") {
          Stmt("""
          guard case let .array(arrayValue) = value else {
            throw UIEventDecodingFailed.encodedValueIsNotArray(
              description: .init(describing: value)
            )
          }
          """)

          "var iterator = arrayValue.makeIterator()" as VariableDecl
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

                    let nextEventExpr = ClosureExpr(
                      signature: ClosureSignature(
                        leadingTrivia: .space,
                        asyncKeyword: "async ",
                        throwsTok: .throws,
                        output: .init(
                          returnType: "\(structName) " as Type
                        )
                      ),
                      statements: .init {
                        Stmt("""
                        guard !Task.isCancelled, let next = iterator.next() else {
                          return nil
                        }
                        """)

                        let arrayConditions = ConditionElementList {
                          .init(
                            condition: .optionalBinding(
                              OptionalBindingCondition(
                                letOrVarKeyword: .let,
                                pattern: "arrayValue" as Pattern,
                                initializer: .init(
                                  value: AsExpr(
                                    expression: "next" as Expr,
                                    typeName: "[MessageValue]" as Type
                                  )
                                )
                              )
                            )
                          )
                        }
                        GuardStmt(conditions: arrayConditions) {
                          Stmt("""
                          throw UIEventDecodingFailed.encodedValueIsNotArray(
                            description: .init(describing: next)
                          )
                          """)
                        }

                        let parameterConditions = ConditionElementList {
                          for parameter in uiEvent.parameters {
                            let name = parameter.name
                              .camelCasedAssumingSnakeCased(capitalized: false)
                            ConditionElement(
                              condition: .optionalBinding(
                                OptionalBindingCondition(
                                  letOrVarKeyword: .let,
                                  pattern: "\(name)" as Pattern,
                                  typeAnnotation: nil,
                                  initializer: .init(
                                    value: UnresolvedPatternExpr(pattern: AsTypePattern(
                                      pattern: "\(name)" as Pattern,
                                      type: "\(parameter.type.swift.signature)" as Type
                                    ))
                                  )
                                )
                              )
                            )
                          }
                        }
                        GuardStmt(conditions: parameterConditions) {
                          Stmt("""
                          throw UIEventDecodingFailed.invalidEncodedValue(
                            description: .init(describing: arrayValue)
                          )
                          """)
                        }

                        let arguments = uiEvent.parameters
                          .map { parameter -> TupleExprElement in
                            let name = parameter.name
                              .camelCasedAssumingSnakeCased(capitalized: false)
                            return TupleExprElement(
                              label: String(name),
                              expression: "\(name)" as Expr
                            )
                          }
                        ReturnStmt(
                          returnKeyword: .return,
                          expression: FunctionCallExpr(
                            calledExpression: "\(structName)" as IdentifierExpr,
                            argumentList: .init(arguments)
                          )
                        )
                      }
                    )
                    VariableDecl(.let, name: "nextEvent", initializer: .init(value: nextEventExpr))
                    "self = .\(caseName)(.init(unfolding: nextEvent))" as Expr
                  }
                }

                SwitchCase("default:") {
                  "throw UIEventDecodingFailed.unknownName(name)" as ThrowStmt
                }
              }
            },
            rightBrace: .rightBrace
          )
        }

        for uiEvent in metadata.uiEvents {
          let caseName = uiEvent.name
            .camelCasedAssumingSnakeCased(capitalized: false)

          let structName = uiEvent.name
            .camelCasedAssumingSnakeCased(capitalized: true)

          EnumCaseDecl("case \(caseName)(AsyncThrowingStream<\(structName), Error>)")

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
    }
  }
}
