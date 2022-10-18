//
//  CustomLoggable.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 17.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public protocol CustomLoggable {
  var logTitle: String? { get }
  var logMessage: String { get }
  var logChildren: [Any] { get }
}

public extension CustomLoggable {
  var logTitle: String? {
    nil
  }

  var logMessage: String {
    "\(self)"
  }

  var logChildren: [Any] {
    []
  }
}

extension String: CustomLoggable {
  public var logMessage: String {
    var text = self.trimmingCharacters(in: .whitespacesAndNewlines)

    if let first = text.first, first.isLowercase {
      text = first.uppercased() + text.dropFirst()
    }

    if text.last != "." {
      text += "."
    }

    return text
  }
}
