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

  var lastMsgShowsWindowFrame: CGRect? {
    get {
      guard
        let x = value(forKey: "msgShowsWindowX") as? Double,
        let y = value(forKey: "msgShowsWindowY") as? Double,
        let width = value(forKey: "msgShowsWindowWidth") as? Double,
        let height = value(forKey: "msgShowsWindowHeight") as? Double
      else {
        return nil
      }
      return .init(x: x, y: y, width: width, height: height)
    }
    set(value) {
      if let value {
        set(value.origin.x, forKey: "msgShowsWindowX")
        set(value.origin.y, forKey: "msgShowsWindowY")
        set(value.width, forKey: "msgShowsWindowWidth")
        set(value.height, forKey: "msgShowsWindowHeight")
      } else {
        removeObject(forKey: "msgShowsWindowX")
        removeObject(forKey: "msgShowsWindowY")
        removeObject(forKey: "msgShowsWindowWidth")
        removeObject(forKey: "msgShowsWindowHeight")
      }
    }
  }

  var appKitFont: NSFont? {
    get {
      guard
        let name = value(forKey: "fontName") as? String,
        let size = value(forKey: "fontSize") as? Double
      else {
        return nil
      }
      return .init(name: name, size: size)
    }
    set(value) {
      if let value {
        set(value.fontName, forKey: "fontName")
        set(value.pointSize, forKey: "fontSize")
      } else {
        removeObject(forKey: "fontName")
        removeObject(forKey: "fontSize")
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
