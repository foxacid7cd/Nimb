// SPDX-License-Identifier: MIT

import AppKit
import NimbState

public extension UserDefaults {
  var lastWindowSize: CGSize? {
    get {
      guard
        let width = value(forKey: "windowWidth") as? Double,
        let height = value(forKey: "windowHeight") as? Double
      else {
        return nil
      }
      return .init(width: width, height: height)
    }
    set(value) {
      if let value {
        set(value.width, forKey: "windowWidth")
        set(value.height, forKey: "windowHeight")
      } else {
        removeObject(forKey: "windowWidth")
        removeObject(forKey: "windowHeight")
      }
    }
  }

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
