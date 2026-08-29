// SPDX-License-Identifier: MIT

import Foundation

/// A concrete stream rather than an associated type, so the transport can be
/// swapped underneath a running RPC.
public protocol Channel: Sendable {
  var dataBatches: AsyncStream<Data> { get }
  func write(_ data: Data) throws
}
