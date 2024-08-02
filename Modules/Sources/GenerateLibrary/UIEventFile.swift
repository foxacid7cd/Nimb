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

  public var sourceFile: SourceFileSyntax {
    get throws {
      try .init {
        try .init {
          "import MessagePack" as DeclSyntax
          "import CasePaths" as DeclSyntax
          "import Library" as DeclSyntax

          try EnumDeclSyntax("public enum UIEvent: Sendable, Equatable") {
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

                "case \(raw: caseName)(\(raw: parametersSignature))" as DeclSyntax

              } else {
                "case \(raw: caseName)" as DeclSyntax
              }
            }
          }

          try ExtensionDeclSyntax("public extension Array<UIEvent>") {
            try InitializerDeclSyntax(
              "init(rawRedrawNotificationParameters: some Sequence<Value>) throws"
            ) {
              "var accumulator = [UIEvent]()" as DeclSyntax

              try ForStmtSyntax("for rawParameter in rawRedrawNotificationParameters") {
                StmtSyntax(
                  """
                  guard case let .array(rawParameter) = rawParameter else {
                    throw Failure(rawRedrawNotificationParameters)
                  }
                  """
                )

                StmtSyntax(
                  """
                  guard case let .string(uiEventName) = rawParameter.first else {
                    throw Failure(rawRedrawNotificationParameters)
                  }
                  """
                )

                try SwitchExprSyntax("switch uiEventName") {
                  try SwitchCaseListSyntax {
                    for uiEvent in metadata.uiEvents {
                      try SwitchCaseSyntax("case \(literal: uiEvent.name):") {
                        let caseName = uiEvent.name.camelCasedAssumingSnakeCased(capitalized: false)

                        try ForStmtSyntax("for rawUIEvent in rawParameter.dropFirst()") {
                          StmtSyntax(
                            """
                            guard case let .array(rawUIEventParameters) = rawUIEvent else {
                              throw Failure(rawRedrawNotificationParameters)
                            }
                            """
                          )

                          let parametersCountCondition =
                            "rawUIEventParameters.count == \(uiEvent.parameters.count)"
                          let (valueParameters, otherParameters) = uiEvent.parameters
                            .enumerated()
                            .partitioned(by: {
                              $0.element.type.swift[case: \.value] == nil
                            })

                          let parameterTypeConditions = otherParameters
                            .map { index, parameter -> String in
                              let identifier = parameter.name
                                .camelCasedAssumingSnakeCased(capitalized: false)
                              let initializer = parameter.type.wrapWithValueDecoder(
                                "rawUIEventParameters[\(index)]",
                                name: identifier
                              )
                              return initializer
                            }

                          let guardConditions = [
                            [parametersCountCondition],
                            parameterTypeConditions,
                          ]
                          .flatMap { $0 }
                          .joined(separator: ", ")

                          StmtSyntax(
                            """
                            guard \(raw: guardConditions) else {
                              throw Failure(rawRedrawNotificationParameters)
                            }
                            """
                          )

                          for (index, parameter) in valueParameters {
                            let identifier = parameter.name
                              .camelCasedAssumingSnakeCased(capitalized: false)
                            DeclSyntax(
                              "let \(raw: identifier) = rawUIEventParameters[\(raw: index)]"
                            )
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

                            ExprSyntax(
                              """
                              accumulator.append(
                                .\(raw: caseName)(\(raw: associatedValuesSignature))
                              )
                              """
                            )

                          } else {
                            ExprSyntax(
                              "accumulator.append(.\(raw: caseName))"
                            )
                          }
                        }
                      }
                    }

                    SwitchCaseSyntax("default:") {
                      "throw Failure(rawRedrawNotificationParameters)" as StmtSyntax
                    }
                  }
                }
              }

              ExprSyntax(
                "self = accumulator"
              )
            }
          }
        }
      }
    }
  }
}
