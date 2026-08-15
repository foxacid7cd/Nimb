// SPDX-License-Identifier: MIT

import Foundation

public extension Bundle {
  var version: (major: Int, minor: Int, patch: Int)? {
    guard let version = infoDictionary?["CFBundleShortVersionString"] as? String else {
      return nil
    }
    let numbers = version
      .components(separatedBy: ".")
      .compactMap { Int($0) }
    guard numbers.count == 3 else {
      logger.fault("Invalid CFBundleShortVersionString: \(version)")
      return nil
    }
    return (numbers[0], numbers[1], numbers[2])
  }
}
