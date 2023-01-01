// SPDX-License-Identifier: MIT

import Algorithms
import CasePaths
import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

public struct UIEventFile: GeneratableFile {
  public init(metadata: Metadata) { self.metadata = metadata }

  public var metadata: Metadata

  public var name: String { "UIEvent" }

  public var sourceFile: SourceFile {
    SourceFile {
      "import MessagePack" as ImportDecl
      "import CasePaths" as ImportDecl

      EnumDecl("public enum UIEvent: Sendable, Equatable") {
        for uiEvent in metadata.uiEvents {
          let caseName = uiEvent.name.camelCasedAssumingSnakeCased(capitalized: false)

          if !uiEvent.parameters.isEmpty {
            let parametersSignature: String = uiEvent.parameters
              .map { parameter in
                let name = parameter.name.camelCasedAssumingSnakeCased(
                  capitalized: false
                )
                let type = parameter.type.swift.signature
                return "\(name): \(type)"
              }
              .joined(separator: ", ")

            "case \(raw: caseName)(\(raw: parametersSignature))" as EnumCaseDecl

          } else {
            "case \(raw: caseName)" as EnumCaseDecl
          }
        }
      }

      ExtensionDecl("public extension Array<UIEvent>") {
        InitializerDecl("init(rawRedrawNotificationParameters: [Value]) throws") {
          "var accumulator = [UIEvent]()" as VariableDecl
          ForInStmt("for rawParameter in rawRedrawNotificationParameters") {
            GuardStmt(
              """
              guard let rawParameter = (/Value.array).extract(from: rawParameter) else {
                throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
              }
              """
            )

            GuardStmt(
              """
              guard let uiEventName = rawParameter.first.flatMap(/Value.string) else {
                throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
              }
              """
            )

            SwitchStmt(
              switchKeyword: .switch,
              expression: "uiEventName" as IdentifierExpr,
              leftBrace: .leftBrace,
              cases: .init {
                SwitchCaseList {
                  for uiEvent in metadata.uiEvents {
                    SwitchCase("case \(literal: uiEvent.name):") {
                      let caseName = uiEvent.name.camelCasedAssumingSnakeCased(capitalized: false)

                      ForInStmt("for rawUIEvent in rawParameter.dropFirst()") {
                        Stmt(
                          """
                          guard let rawUIEventParameters = (/Value.array).extract(from: rawUIEvent) else {
                            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
                          }
                          """
                        )

                        let parametersCountCondition = "rawUIEventParameters.count == \(uiEvent.parameters.count)"
                        let (valueParameters, otherParameters) = uiEvent.parameters
                          .enumerated()
                          .partitioned(by: {
                            (/ValueType.SwiftType.value)
                              .extract(from: $0.element.type.swift) == nil
                          })

                        let parameterTypeConditions = otherParameters
                          .map { index, parameter -> String in
                            let identifier = parameter.name.camelCasedAssumingSnakeCased(capitalized: false)
                            let initializer = parameter.type.wrapWithValueDecoder("rawUIEventParameters[\(index)]")
                            return "let \(identifier) = \(initializer)"
                          }

                        let guardConditions = [
                          [parametersCountCondition],
                          parameterTypeConditions,
                        ]
                        .flatMap { $0 }
                        .joined(separator: ", ")

                        Stmt(
                          """
                          guard \(raw: guardConditions) else {
                            throw UIEventsDecodingFailure(rawRedrawNotificationParameters)
                          }
                          """
                        )

                        for (index, parameter) in valueParameters {
                          let identifier = parameter.name.camelCasedAssumingSnakeCased(capitalized: false)
                          "let \(raw: identifier) = rawUIEventParameters[\(raw: index)]" as VariableDecl
                        }

                        if !uiEvent.parameters.isEmpty {
                          let associatedValuesSignature = uiEvent.parameters
                            .map { parameter in
                              let name = parameter.name.camelCasedAssumingSnakeCased(
                                capitalized: false
                              )
                              return "\(name): \(name)"
                            }
                            .joined(separator: ", ")

                          Expr(
                            """
                            accumulator.append(
                              .\(raw: caseName)(\(raw: associatedValuesSignature))
                            )
                            """
                          )

                        } else {
                          "accumulator.append(.\(raw: caseName))" as Expr
                        }
                      }
                    }
                  }

                  SwitchCase("default:") {
                    "throw UIEventsDecodingFailure(rawRedrawNotificationParameters)" as Stmt
                  }
                }
              }
            )
          }

          "self = accumulator" as SequenceExpr
        }
      }

      StructDecl(
        """
        public struct UIEventsDecodingFailure: Error {
          public init(_ rawRedrawNotificationParameters: [Value], lineNumber: UInt = #line) {
            self.rawRedrawNotificationParameters = rawRedrawNotificationParameters
            self.lineNumber = lineNumber
          }

          public var rawRedrawNotificationParameters: [Value]
          public var lineNumber: UInt
        }
        """
      )
    }
  }
}
