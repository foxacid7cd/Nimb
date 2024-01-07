// SPDX-License-Identifier: MIT

import Foundation
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

  var fontName: String? {
    get {
      value(forKey: "fontName") as? String
    }
    set(value) {
      set(value, forKey: "fontName")
    }
  }

  var fontSize: Double? {
    get {
      value(forKey: "fontSize") as? Double
    }
    set(value) {
      set(value, forKey: "fontSize")
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
}
