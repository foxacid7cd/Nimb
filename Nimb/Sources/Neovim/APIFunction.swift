// SPDX-License-Identifier: MIT

public protocol APIFunction: Sendable {
  associatedtype Success
  static var method: String { get }
  var parameters: [Value] { get }
  static func decodeSuccess(from raw: Value) throws -> Success
}

public extension APIFunction where Success == Value {
  static func decodeSuccess(from raw: Value) throws -> Value {
    raw
  }
}
