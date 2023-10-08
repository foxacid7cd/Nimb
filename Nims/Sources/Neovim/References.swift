// SPDX-License-Identifier: MIT

import Foundation

public enum References {
  public struct Buffer: Sendable, Hashable {
    public init(data: Data) {
      self.data = data
    }

    public init?(type: Int8, data: Data) {
      guard type == References.Buffer.type else {
        return nil
      }
      self = .init(data: data)
    }

    public static var type: Int8 {
      0
    }

    public var data: Data
  }

  public struct Window: Sendable, Hashable {
    public init(data: Data) {
      self.data = data
    }

    public init?(type: Int8, data: Data) {
      guard type == References.Window.type else {
        return nil
      }
      self = .init(data: data)
    }

    public static var type: Int8 {
      1
    }

    public var data: Data
  }

  public struct Tabpage: Sendable, Hashable {
    public init(data: Data) {
      self.data = data
    }

    public init?(type: Int8, data: Data) {
      guard type == References.Tabpage.type else {
        return nil
      }
      self = .init(data: data)
    }

    public static var type: Int8 {
      2
    }

    public var data: Data
  }
}
