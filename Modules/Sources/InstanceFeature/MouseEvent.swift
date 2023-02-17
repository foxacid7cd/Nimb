// SPDX-License-Identifier: MIT

import Library

public struct MouseEvent: Equatable {
  public init(content: MouseEvent.Content, gridID: Grid.ID, point: IntegerPoint) {
    self.content = content
    self.gridID = gridID
    self.point = point
  }

  public enum Content: Equatable {
    case mouse(button: MouseButton, action: MouseAction)
    case scrollWheel(direction: ScrollDirection)

    public enum MouseButton: String {
      case left
      case right
      case middle
    }

    public enum MouseAction: String {
      case press
      case drag
      case release
    }

    public enum ScrollDirection: String {
      case up
      case down
      case left
      case right
    }
  }

  public var content: Content
  public var gridID: Grid.ID
  public var point: IntegerPoint
}
