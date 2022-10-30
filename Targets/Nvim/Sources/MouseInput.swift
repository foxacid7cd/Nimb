//
//  MouseInput.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 30.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Library

public struct MouseInput {
  public init(event: Event, gridID: Int, point: GridPoint) {
    self.event = event
    self.gridID = gridID
    self.point = point
  }

  public enum Event {
    case button(Button, action: ButtonAction)
    case wheel(action: WheelAction)
    case move

    public var nvimAction: String {
      switch self {
      case let .button(_, action):
        return action.rawValue

      case let .wheel(action):
        return action.rawValue

      case .move:
        return ""
      }
    }

    public var nvimButton: String {
      switch self {
      case let .button(button, _):
        return button.rawValue

      case .wheel:
        return "wheel"

      case .move:
        return "move"
      }
    }
  }

  public enum Button: String {
    case left
    case right
    case middle
  }

  public enum ButtonAction: String {
    case press
    case drag
    case release
  }

  public enum WheelAction: String {
    case up
    case down
    case left
    case right
  }

  public var event: Event
  public var gridID: Int
  public var point: GridPoint
}
