// Copyright © 2022 foxacid7cd. All rights reserved.

public extension StringProtocol {
  var camelCased: String {
    components(separatedBy: "_")
      .enumerated()
      .map { offset, word in
        offset == 0 ? word : word.capitalized
      }
      .joined()
  }
}
