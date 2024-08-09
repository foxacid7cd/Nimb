// SPDX-License-Identifier: MIT

@attached(member, names: named(init))
public macro PublicInit() = #externalMacro(
  module: "MacrosTarget",
  type: "PublicInitMacro"
)
