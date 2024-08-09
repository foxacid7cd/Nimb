// SPDX-License-Identifier: MIT

@propertyWrapper
struct UncheckedSendable<Value>: @unchecked Sendable {
  var wrappedValue: Value

  var projectedValue: Self { self }

  init(wrappedValue value: Value) {
    wrappedValue = value
  }
}
