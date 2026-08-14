// SPDX-License-Identifier: MIT

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MyMacroPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    PublicInitMacro.self,
  ]
}
