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

          EnumCaseDecl("case \(caseName)(AsyncThrowingStream<UIEvents.\(structName), Error>)")
        }

        InitializerDecl("init(_ value: Value) throws") {
          Stmt("""
          guard case let .array(arrayValue) = value else {
            throw UIEventDecodingError.encodedValueIsNotArray(
              details: .init(describing: value)
            )
          }
          """)

          "var iterator = arrayValue.makeIterator()" as VariableDecl
          "let nameValue = iterator.next()" as VariableDecl

          Stmt("""
          guard case let .string(name) = nameValue else {
            throw UIEventDecodingError.invalidName(
              .init(describing: nameValue)
            )
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

                    let nextEventExpr = ClosureExpr(
                      signature: ClosureSignature(
                        leadingTrivia: .space,
                        input: .input(.init()),
                        asyncKeyword: "async ",
                        throwsTok: .throws,
                        output: .init(
                          returnType: "UIEvents.\(structName)? " as Type
                        )
                      ),
                      statements: .init {
                        Stmt("""
                        guard !Task.isCancelled, let next = iterator.next() else {
                          return nil
                        }
                        """)

                        Stmt("""
                        guard case let .array(arrayValue) = next else {
                          throw UIEventDecodingError.encodedValueIsNotArray(
                            details: "UI event name (\(uiEvent.name)), value " + String(describing: next)
                          )
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
                          throw UIEventDecodingError.invalidEncodedValue(
                            details: "UI event name (\(uiEvent.name)), value " + String(describing: next)
                          )
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
                    VariableDecl(.let, name: "nextEvent", initializer: .init(value: nextEventExpr))
                    "self = .\(caseName)(.init(unfolding: nextEvent))" as Expr
                  }
                }

                SwitchCase("default:") {
                  "throw UIEventDecodingError.invalidName(name)" as ThrowStmt
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
