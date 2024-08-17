// SPDX-License-Identifier: MIT

public struct State: Sendable {
  public struct Updates: Sendable {
    public var isAppearanceChanged: Bool = false
  }

  public var highlights: IntKeyedDictionary<Highlight> = [:]
  public var defaultForegroundColor: Color = .black
  public var defaultBackgroundColor: Color = .black
  public var defaultSpecialColor: Color = .black
  public var options: [String: Value] = [:]

  public mutating func apply(_ uiEvents: [UIEvent]) -> Updates {
    var updates = Updates()
    for uiEvent in uiEvents {
      switch uiEvent {
      case let .optionSet(name, value):
        options[name] = value
        updates.isAppearanceChanged = true

      default:
        break
      }
    }
    return updates
  }
}
