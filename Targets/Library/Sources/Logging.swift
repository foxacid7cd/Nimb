//
//  Logging.swift
//  Library
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import OSLog

public protocol CustomLoggable {
  var logTitle: String { get }
  var logMessage: String { get }
}

private let osLog = OSLog.default

public func log(_ logLevel: OSLogType, file: StaticString = #fileID, line: UInt = #line, _ items: Any...) {
  let message = items
    .map { "\($0)" }
    .joined(separator: "\n")

  print("~\n~")
  os_log(logLevel, log: osLog, "\n\(message)")
}
