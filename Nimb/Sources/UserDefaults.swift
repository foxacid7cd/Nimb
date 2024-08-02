// SPDX-License-Identifier: MIT

import AppKit
import CasePaths
import Library

public extension UserDefaults {
  var outerGridSize: IntegerSize {
    get {
      guard
        let columnsCount = value(forKey: "columnsCount") as? Int,
        let rowsCount = value(forKey: "rowsCount") as? Int
      else {
        return .init(columnsCount: 110, rowsCount: 34)
      }
      return .init(columnsCount: columnsCount, rowsCount: rowsCount)
    }
    set(value) {
      set(value.columnsCount, forKey: "columnsCount")
      set(value.rowsCount, forKey: "rowsCount")
    }
  }

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
      guard let isUIEventsLoggingEnabled = value(forKey: "isUIEventsLoggingEnabled") as? Bool else {
        return .init(isUIEventsLoggingEnabled: false)
      }
      return .init(isUIEventsLoggingEnabled: isUIEventsLoggingEnabled)
    }
    set(value) {
      set(value.isUIEventsLoggingEnabled, forKey: "isUIEventsLoggingEnabled")
    }
  }

  var environmentOverlay: [String: String] {
    get {
      guard
        let encoded = value(forKey: "environmentOverlay") as? Data,
        let value = try? JSONDecoder().decode([String: String].self, from: encoded)
      else {
        return [:]
      }
      return value
    }
    set(value) {
      let encoded = try? JSONEncoder().encode(value)
      setValue(encoded, forKey: "environmentOverlay")
    }
  }

  var vimrc: Vimrc {
    get {
      var value = Vimrc.default
      if let encoded = self.value(forKey: "vimrc") as? String {
        switch encoded {
        case "norc":
          value = .norc
        case "none":
          value = .none
        default:
          value = .custom(.init(filePath: encoded))
        }
      }
      return value
    }
    set(value) {
      let encoded: String? =
        switch value {
        case .default:
          nil
        case .norc:
          "norc"
        case .none:
          "none"
        case let .custom(url):
          url.standardizedFileURL.path()
        }
      setValue(encoded, forKey: "vimrc")
    }
  }
}

@CasePathable
public enum Vimrc {
  case `default`
  case norc
  case none
  case custom(URL)
}
