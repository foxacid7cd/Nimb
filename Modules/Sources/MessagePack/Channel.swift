// SPDX-License-Identifier: MIT

import Foundation

public protocol Channel: Sendable {
  associatedtype S: AsyncSequence where S.Element == Data

  var dataBatches: S { get async }
  func write(_ data: Data) async throws
}
