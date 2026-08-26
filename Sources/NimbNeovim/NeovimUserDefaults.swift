// SPDX-License-Identifier: MIT

import Foundation
import NimbCore

/// Preferences that configure the embedded Neovim process itself, as opposed
/// to the application's own window and appearance settings, which stay in the
/// app target.
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

  var environmentOverlay: [String: String] {
    get {
      guard
        let encoded = value(forKey: "environmentOverlay") as? Data,
        let value = try? JSONDecoder().decode(
          [String: String].self,
          from: encoded,
        )
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
          url.standardizedFileURL.path(percentEncoded: false)
        }
      setValue(encoded, forKey: "vimrc")
    }
  }
}

public enum Vimrc {
  case `default`
  case norc
  case none
  case custom(URL)
}
