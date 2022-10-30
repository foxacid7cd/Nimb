//
//  Anchor.swift
//  Nvim
//
//  Created by Yevhenii Matviienko on 30.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public enum Anchor: String {
  case topLeft = "NW"
  case topRight = "NE"
  case bottomLeft = "SW"
  case bottomRight = "SE"
}

public extension UIEvents.WinFloatPos {
  var anchorValue: Anchor {
    guard let value = Anchor(rawValue: self.anchor) else {
      "unknown anchor string: \(self.anchor)"
        .fail()
        .assertionFailure()

      return .topLeft
    }

    return value
  }
}
