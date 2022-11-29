//
//  CustomLoggable.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 17.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public protocol CustomLoggable {
  var logMessage: String { get }
  var logChildren: [Any] { get }
}

public extension CustomLoggable {
  var logMessage: String {
    "\(self)"
  }

  var logChildren: [Any] {
    []
  }
}

public extension String {
  func loggable(_ children: Any...) -> CustomLoggable {
    Wrapper(logMessage: self, logChildren: children)

    struct Wrapper: CustomLoggable {
      var logMessage: String
      var logChildren: [Any]
    }
  }
}
