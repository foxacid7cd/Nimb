// SPDX-License-Identifier: MIT

import Foundation
import NimbState

public extension UserDefaults {
  var debug: State.Debug {
    get {
      guard
        let data = value(forKey: "debug") as? Data,
        let debug = try? JSONDecoder().decode(State.Debug.self, from: data)
      else {
        return .init()
      }
      return debug
    }
    set(value) {
      let data = try! JSONEncoder().encode(value)
      set(data, forKey: "debug")
    }
  }
}
