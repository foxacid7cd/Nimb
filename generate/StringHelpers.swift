// SPDX-License-Identifier: MIT

private let acronyms: Set<String> = ["ID", "IDX", "RPC", "UI", "URL", "UUID"]

public extension StringProtocol {
  func camelCasedAssumingSnakeCased(capitalized: Bool) -> String {
    components(separatedBy: "_")
      .filter { !$0.isEmpty }
      .map { $0.prefix(1).lowercased() + $0.dropFirst(1) }
      .enumerated()
      .map { offset, word in
        let uppercased = word.uppercased()
        let isAcronym = acronyms.contains(uppercased)
        let shouldCapitalize = offset != 0 || capitalized
        return shouldCapitalize ? isAcronym ? uppercased : word
          .capitalized : word
      }
      .joined()
  }
}
