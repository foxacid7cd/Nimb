// SPDX-License-Identifier: MIT

import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct MergeableMacro: MemberMacro {
  enum Error: String, Swift.Error, DiagnosticMessage {
    case notAStruct

    var diagnosticID: MessageID {
      .init(domain: "MergeableMacro", id: rawValue)
    }

    var severity: DiagnosticSeverity {
      .error
    }

    var message: String {
      switch self {
      case .notAStruct: "@Mergeable can only be applied to structs"
      }
    }
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext,
  ) throws
  -> [DeclSyntax] {
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      throw Error.notAStruct
    }

    var statements = [String]()
    var hasCustomMerged = false

    for property in structDecl.storedProperties {
      guard
        let type = property.bindings.first?.typeAnnotation?.type
          .trimmedDescription
      else {
        continue
      }
      let name = property.identifier.text

      if property.hasAttribute(named: "MergeCustom") {
        hasCustomMerged = true

      } else if property.hasAttribute(named: "MergeReplacing") {
        statements.append("\(name) = other.\(name)")

      } else if type == "Bool" {
        statements.append("\(name) = \(name) || other.\(name)")

      } else {
        statements.append("\(name).formUnion(other.\(name))")
      }
    }

    if hasCustomMerged {
      statements.insert("mergeCustom(other)", at: 0)
    }

    let formUnion: DeclSyntax = """
    public mutating func formUnion(_ other: Self) {
    \(raw: statements.joined(separator: "\n"))
    }
    """

    return [formUnion]
  }
}

/// Expands to nothing: `@MergeReplacing` and `@MergeCustom` exist only for
/// `@Mergeable` to read off the properties they are attached to.
public struct MergeMarkerMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext,
  ) throws
  -> [DeclSyntax] {
    []
  }
}

extension VariableDeclSyntax {
  func hasAttribute(named name: String) -> Bool {
    attributes.contains { attribute in
      attribute.as(AttributeSyntax.self)?.attributeName
        .trimmedDescription == name
    }
  }
}
