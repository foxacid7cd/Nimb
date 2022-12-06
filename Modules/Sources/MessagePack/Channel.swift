// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation

public protocol Channel {
  associatedtype S: AsyncSequence where S.Element == Data

  var dataBatches: S { get async }
  func write(_ data: Data) async throws
}
