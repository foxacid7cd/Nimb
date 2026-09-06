// SPDX-License-Identifier: MIT

@attached(member, names: named(init))
public macro PublicInit() = #externalMacro(
  module: "NimbMacros",
  type: "PublicInitMacro",
)

/// Generates `formUnion(_:)` over the stored properties: `Bool` fields are
/// ored, every other field gets its own `formUnion`.
@attached(member, names: named(formUnion))
public macro Mergeable() = #externalMacro(
  module: "NimbMacros",
  type: "MergeableMacro",
)

/// The property is overwritten by the incoming value rather than merged.
@attached(peer)
public macro MergeReplacing() = #externalMacro(
  module: "NimbMacros",
  type: "MergeMarkerMacro",
)

/// The property is left to `mergeCustom(_:)`, which the generated `formUnion`
/// calls before merging anything else.
@attached(peer)
public macro MergeCustom() = #externalMacro(
  module: "NimbMacros",
  type: "MergeMarkerMacro",
)
