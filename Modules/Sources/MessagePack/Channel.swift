// SPDX-License-Identifier: MIT

import Foundation

public protocol Channel: Sendable {
  associatedtype S: AsyncSequence where S.Element == Data, S: Sendable

  var dataBatches: S { get }
  func write(_ data: Data) async throws
}
