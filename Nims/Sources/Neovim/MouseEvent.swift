// SPDX-License-Identifier: MIT

import Library

@PublicInit
public struct MouseEvent: Equatable, Sendable {
  public enum Content: Equatable, Sendable {
    case mouseButton(MouseButton, action: MouseAction)
    case mouseMove
    case scrollWheel(direction: ScrollDirection)

    public enum MouseButton: String, Sendable {
      case left
      case right
      case middle
    }

    public enum MouseAction: String, Sendable {
      case press
      case drag
      case release
    }

    public enum ScrollDirection: String, Sendable {
      case up
      case down
      case left
      case right
    }
  }

  public var content: Content
  public var gridID: Grid.ID
  public var point: IntegerPoint
  public var modifier: String
}
