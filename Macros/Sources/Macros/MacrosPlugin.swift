// SPDX-License-Identifier: MIT

@_exported import SwiftCompilerPlugin
@_exported import SwiftDiagnostics
@_exported import SwiftSyntax
@_exported import SwiftSyntaxBuilder
@_exported import SwiftSyntaxMacros

@main
struct MacroKitPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [PublicInitMacro.self]
}
