// SPDX-License-Identifier: MIT

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct NimbMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    PublicInitMacro.self,
  ]
}
