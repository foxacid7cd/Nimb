// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation

public protocol Channel {
  var dataBatches: AsyncStream<Data> { get async }
  func write(_ data: Data) async throws
}
