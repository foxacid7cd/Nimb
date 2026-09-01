// SPDX-License-Identifier: MIT

import Foundation
import NimbCore

@PublicInit
public struct SavedWindowGeometry: Codable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case contentSize
    case columnsCount
    case rowsCount
  }

  public var contentSize: CGSize
  public var outerGridSize: IntegerSize

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    contentSize = try container.decode(CGSize.self, forKey: .contentSize)
    outerGridSize = try .init(
      columnsCount: container.decode(Int.self, forKey: .columnsCount),
      rowsCount: container.decode(Int.self, forKey: .rowsCount),
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(contentSize, forKey: .contentSize)
    try container.encode(outerGridSize.columnsCount, forKey: .columnsCount)
    try container.encode(outerGridSize.rowsCount, forKey: .rowsCount)
  }
}

/// Preferences shared by the embedded Neovim process and the app.
public extension UserDefaults {
  var savedWindowGeometry: SavedWindowGeometry? {
    get {
      if
        let data = value(forKey: "windowGeometry") as? Data,
        let geometry = try? JSONDecoder().decode(SavedWindowGeometry.self, from: data)
      {
        return geometry
      }

      guard
        let width = value(forKey: "windowWidth") as? Double,
        let height = value(forKey: "windowHeight") as? Double,
        let columnsCount = value(forKey: "columnsCount") as? Int,
        let rowsCount = value(forKey: "rowsCount") as? Int
      else {
        return nil
      }

      return .init(
        contentSize: .init(width: width, height: height),
        outerGridSize: .init(
          columnsCount: columnsCount,
          rowsCount: rowsCount,
        ),
      )
    }
    set(geometry) {
      if let geometry {
        guard let data = try? JSONEncoder().encode(geometry) else {
          return
        }
        set(data, forKey: "windowGeometry")
      } else {
        removeObject(forKey: "windowGeometry")
      }
      removeObject(forKey: "windowWidth")
      removeObject(forKey: "windowHeight")
      removeObject(forKey: "columnsCount")
      removeObject(forKey: "rowsCount")
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
