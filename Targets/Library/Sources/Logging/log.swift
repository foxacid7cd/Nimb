//
//  Logging.swift
//  Library
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import OSLog

public func log(_ logLevel: OSLogType, log: OSLog = .default, file: StaticString = #fileID, line: UInt = #line, _ item: Any) {
  let title = [
    logLevel.name?.uppercased(),
    "\(file):\(line)"
  ]
  .compactMap { $0 }
  .joined(separator: " @ ")

  print("")
  os_log(logLevel, log: log, "\n :\n\(String(loggable: item, title: title))")
}

public extension String {
  init(loggable: Any, title: String? = nil) {
    self = logLines(for: loggable, title: title)
      .joined(separator: "\n")
  }
}

private func logLines(for item: Any, title: String? = nil) -> [String] {
  let loggable = item as? CustomLoggable

  let title = [title, loggable?.logTitle]
    .compactMap { $0 }
    .joined(separator: " @ ")
  let message = loggable?.logMessage ?? "\(item)"
  let children = loggable?.logChildren ?? []

  var lines = [String]()
  if !title.isEmpty {
    lines.append("-> \(title)")
  }

  lines += message
    .trimmingCharacters(in: .whitespacesAndNewlines)
    .split(separator: "\n", omittingEmptySubsequences: false)
    .map { " \($0.trimmingCharacters(in: .whitespaces))" }

  for child in children {
    lines.append("")
    lines += logLines(for: child)
  }

  var prefixedLines = [String]()
  var verticalBar = true
  for (index, line) in lines.enumerated() {
    let isFirst = index == 0
    let isLast = index == lines.count - 1

    if index != 0, line.first == "-" {
      verticalBar = false
    }

    let prefix: String = {
      let first = isFirst ? "-" : " "
      let second: String = {
        if isFirst {
          return "*"
        } else if line.first == "-", !isLast {
          return "*"
        } else if isLast, children.isEmpty {
          return "*"
        } else if verticalBar {
          return "|"
        } else {
          return " "
        }
      }()
      return first + second
    }()

    prefixedLines.append(prefix + line)
  }
  return prefixedLines
}

private extension OSLogType {
  var name: String? {
    switch self {
    case .default:
      return "default"

    case .info:
      return "info"

    case .debug:
      return "debug"

    case .error:
      return "error"

    case .fault:
      return "fault"

    default:
      return nil
    }
  }
}
