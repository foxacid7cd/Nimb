// Copyright © 2022 foxacid7cd. All rights reserved.

public extension Result {
  func check() throws {
    _ = try get()
  }
}
