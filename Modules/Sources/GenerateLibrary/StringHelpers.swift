// SPDX-License-Identifier: MIT

public extension StringProtocol {
  func camelCasedAssumingSnakeCased(capitalized: Bool) -> some StringProtocol {
    components(separatedBy: "_").filter { !$0.isEmpty }.enumerated()
      .map { offset, word in offset == 0 && !capitalized ? word : word.capitalized }.joined()
  }
}
