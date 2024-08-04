// SPDX-License-Identifier: MIT

public typealias UIOptions = Set<UIOption>

public extension UIOptions {
  var nvimUIAttachOptions: [Value: Value] {
    .init(
      uniqueKeysWithValues: map {
        (key: .string($0.rawValue), value: .boolean(true))
      }
    )
  }
}
