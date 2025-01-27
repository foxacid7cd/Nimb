// SPDX-License-Identifier: MIT

import Algorithms
import CasePaths
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

public struct UIEventFile: GeneratableFile {
  public var metadata: Metadata

  public var name: String { "UIEvent" }

  public var sourceFile: SourceFileSyntax {
    get throws {
      try .init {
        try .init {
          """

          import CasePaths

          """ as DeclSyntax

          try EnumDeclSyntax("public enum UIEvent: Sendable, Equatable") {
            for uiEvent in metadata.uiEvents {
              let caseName = uiEvent.name
                .camelCasedAssumingSnakeCased(capitalized: false)

              if !uiEvent.parameters.isEmpty {
                let structName = uiEvent.name
                  .camelCasedAssumingSnakeCased(capitalized: true)

                """
                case \(raw: caseName)([\(raw: structName)])

                """ as DeclSyntax

              } else {
                """
                case \(raw: caseName)

                """ as DeclSyntax
              }
            }

            for uiEvent in metadata.uiEvents where !uiEvent.parameters.isEmpty {
              let caseName = uiEvent.name
                .camelCasedAssumingSnakeCased(capitalized: false)

              let structName = uiEvent.name
                .camelCasedAssumingSnakeCased(capitalized: true)

              try StructDeclSyntax("""
              @PublicInit
              public struct \(raw: structName): Sendable, Hashable
              """) {
                for parameter in uiEvent.parameters {
                  let name = parameter.name
                    .camelCasedAssumingSnakeCased(capitalized: false)

                  let type = parameter.type.swift.signature

                  """
                  public var \(raw: name): \(raw: type)

                  """ as DeclSyntax
                }
              }
            }
          }

          try ExtensionDeclSyntax("public extension Array<UIEvent>") {
            try InitializerDeclSyntax(
              "init(rawRedrawNotificationParameters: some Sequence<Value>) throws"
            ) {
              """
              var accumulator = [UIEvent]()

              """ as DeclSyntax

              try ForStmtSyntax(
                "for rawParameter in rawRedrawNotificationParameters"
              ) {
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
                      let structName = uiEvent.name
                        .camelCasedAssumingSnakeCased(capitalized: true)

                      try SwitchCaseSyntax("case \(literal: uiEvent.name):") {
                        if !uiEvent.parameters.isEmpty {
                          """
                          var localAccumulator = [UIEvent.\(raw: structName)]()

                          """ as DeclSyntax
                        }

                        let caseName = uiEvent.name
                          .camelCasedAssumingSnakeCased(capitalized: false)

                        try ForStmtSyntax(
                          "for rawUIEvent in rawParameter.dropFirst()"
                        ) {
                          StmtSyntax(
                            """
                            guard case let .array(rawUIEventParameters) = rawUIEvent else {
                              throw Failure(rawRedrawNotificationParameters)
                            }

                            """
                          )

                          let parametersCountCondition =
                            "rawUIEventParameters.count == \(uiEvent.parameters.count)"
                          let (valueParameters, otherParameters) = uiEvent
                            .parameters
                            .enumerated()
                            .partitioned(by: {
                              $0.element.type.swift[case: \.value] == nil
                            })

                          let parameterTypeConditions = otherParameters
                            .map { index, parameter -> String in
                              let identifier = parameter.name
                                .camelCasedAssumingSnakeCased(
                                  capitalized: false
                                )
                              return parameter.type.wrapWithValueDecoder(
                                "rawUIEventParameters[\(index)]",
                                name: identifier
                              )
                            }

                          let guardConditions = [
                            [parametersCountCondition],
                            parameterTypeConditions,
                          ]
                            .flatMap(\.self)
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

                            """
                            let \(raw: identifier) = rawUIEventParameters[\(raw: index)]

                            """ as DeclSyntax
                          }

                          if !uiEvent.parameters.isEmpty {
                            let associatedValuesSignature = uiEvent.parameters
                              .map { parameter in
                                let name = parameter.name
                                  .camelCasedAssumingSnakeCased(
                                    capitalized: false
                                  )
                                return "\(name): \(name)"
                              }
                              .joined(separator: ", ")

                            """
                            localAccumulator.append(
                              .init(\(raw: associatedValuesSignature))
                            )

                            """ as ExprSyntax

                          } else {
                            """
                            accumulator.append(.\(raw: caseName))

                            """ as ExprSyntax
                          }
                        }

                        if !uiEvent.parameters.isEmpty {
                          """
                          accumulator.append(.\(raw: caseName)(localAccumulator))

                          """ as ExprSyntax
                        }
                      }
                    }

                    SwitchCaseSyntax("default:") {
                      "throw Failure(rawRedrawNotificationParameters)" as StmtSyntax
                    }
                  }
                }
              }

              """
              self = accumulator

              """ as ExprSyntax
            }
          }
        }
      }
    }
  }

  public init(metadata: Metadata) { self.metadata = metadata }
}
