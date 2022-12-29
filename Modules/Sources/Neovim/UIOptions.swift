// SPDX-License-Identifier: MIT

import MessagePack

public typealias UIOptions = Set<UIOption>

public extension UIOptions {
  var nvimUIAttachOptions: [Value: Value] {
    .init(
      uniqueKeysWithValues:
      map { uiOption in
        (
          key: Value.string(uiOption.rawValue),
          value: .boolean(true)
        )
      }
    )
  }
}
