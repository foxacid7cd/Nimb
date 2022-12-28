// SPDX-License-Identifier: MIT

private let acronyms: Set<String> = ["ID", "RPC", "UI", "URL", "UUID"]

public extension StringProtocol {
  func camelCasedAssumingSnakeCased(capitalized: Bool) -> String {
    components(separatedBy: "_")
      .filter { !$0.isEmpty }
      .enumerated()
      .map { offset, word in
        offset == 0 && !capitalized ? word : acronyms.contains(word) ? word.uppercased() : word.capitalized
      }
      .joined()
  }
}
