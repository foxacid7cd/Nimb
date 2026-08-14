// SPDX-License-Identifier: MIT

import Foundation
import NimbCore

public protocol Channel: Sendable {
  associatedtype S: AsyncSequence, Sendable where S.Element == Data

  var dataBatches: S { get }
  func write(_ data: Data) throws
}
