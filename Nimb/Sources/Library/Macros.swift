// SPDX-License-Identifier: MIT

@attached(member, names: named(init))
public macro PublicInit() = #externalMacro(
  module: "MyMacroMacros",
  type: "PublicInitMacro"
)
