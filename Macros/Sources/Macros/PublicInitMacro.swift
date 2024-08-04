// SPDX-License-Identifier: MIT

public struct PublicInitMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws
    -> [DeclSyntax]
  {
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      throw Error.notAStruct
    }

    let included = structDecl.storedProperties
      .filter { $0.bindings.first!.typeAnnotation != nil }

    let publicInit: DeclSyntax = """
    public init(
    \(raw: included.map { "\($0.bindings)" }.joined(separator: ",\n"))
    ) {
    \(
      raw: included.map { "self.\($0.identifier) = \($0.identifier)" }
        .joined(separator: "\n")
    )
    }
    """

    return [publicInit]
  }

  enum Error: String, Swift.Error, DiagnosticMessage {
    case notAStruct

    var diagnosticID: MessageID {
      .init(domain: "PublicInitMacro", id: rawValue)
    }

    var severity: DiagnosticSeverity { .error }
    var message: String {
      switch self {
      case .notAStruct: "@PublicInit can only be applied to structs"
      }
    }
  }
}

extension VariableDeclSyntax {
  var isStoredProperty: Bool {
    if bindings.count != 1 {
      return false
    }

    if modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) {
      return false
    }

    let binding = bindings.first!
    switch binding.accessorBlock?.accessors {
    case .none:
      return true

    case let .accessors(accessors):
      for accessor in accessors {
        switch accessor.accessorSpecifier.tokenKind {
        case .keyword(.didSet),
             .keyword(.willSet):
          // Observers can occur on a stored property.
          break

        default:
          // Other accessors make it a computed property.
          return false
        }
      }

      return true

    case .getter:
      return false
    }
  }

  var identifier: TokenSyntax {
    for binding in bindings {
      if
        let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?
          .identifier
      {
        return identifier
      }
    }

    fatalError()
  }
}

extension DeclGroupSyntax {
  var storedProperties: [VariableDeclSyntax] {
    memberBlock.members.compactMap { member in
      guard
        let variable = member.decl.as(VariableDeclSyntax.self),
        variable.isStoredProperty
      else {
        return nil
      }

      return variable
    }
  }
}
