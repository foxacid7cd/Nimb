//
//  log.swift
//  Library
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import OSLog

private let osLog = OSLog.default

public func log(_ logLevel: OSLogType = .default, _ items: Any...) {
  let message = items
    .map { "\($0)" }
    .joined(separator: "\n")

  os_log(logLevel, log: osLog, "\(message)")
}
