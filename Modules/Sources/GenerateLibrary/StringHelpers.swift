// SPDX-License-Identifier: MIT

private let acronyms: Set<String> = ["ID", "IDX", "RPC", "UI", "URL", "UUID"]

public extension StringProtocol {
  func camelCasedAssumingSnakeCased(capitalized: Bool) -> String {
    components(separatedBy: "_")
      .filter { !$0.isEmpty }
      .enumerated()
      .map { offset, word in
        if acronyms.contains(word.uppercased()) {
          offset == 0 && !capitalized ? word : word.uppercased()

        } else {
          offset == 0 && !capitalized ? word : word.capitalized
        }
      }
      .joined()
  }
}
