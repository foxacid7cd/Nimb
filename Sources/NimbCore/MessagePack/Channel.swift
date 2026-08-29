// SPDX-License-Identifier: MIT

import Foundation

/// Stated as a concrete stream rather than an associated type, so RPC can hold
/// any channel and the transport can be swapped underneath it.
public protocol Channel: Sendable {
  var dataBatches: AsyncStream<Data> { get }
  func write(_ data: Data) throws
}
