// SPDX-License-Identifier: MIT

@propertyWrapper
struct UncheckedSendable<Value>: @unchecked Sendable {
  init(wrappedValue value: Value) {
    wrappedValue = value
  }

  var wrappedValue: Value

  var projectedValue: Self { self }
}
