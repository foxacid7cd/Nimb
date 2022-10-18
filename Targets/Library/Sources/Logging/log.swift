//
//  Logging.swift
//  Library
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import OSLog

public func log(_ logLevel: OSLogType, log: OSLog = .default, _ item: @autoclosure @escaping () -> Any, file: StaticString = #fileID, line: UInt = #line) {
  #if !DEBUG
    return
  #endif

  let header = [
    logLevel.name?.uppercased(),
    "\(file):\(line)"
  ]
  .compactMap { $0 }
  .joined(separator: " @ ")

  let string = logLines(for: item(), header: header)
    .joined(separator: "\n")

  print()
  os_log(logLevel, log: log, "\n |\n\(string)\n ")
}

public extension String {
  init(loggable: Any, header: String? = nil) {
    self = logLines(for: loggable, header: header)
      .joined(separator: "\n")
  }
}

private func logLines(for item: Any, header: String?) -> [String] {
  let loggable = item as? CustomLoggable

  let message = loggable?.logMessage ?? "\(item)"
  let children = loggable?.logChildren ?? []

  var lines = [String]()
  if let header {
    lines.append("-> \(header)")
  }

  lines += message
    .trimmingCharacters(in: .whitespacesAndNewlines)
    .split(separator: "\n", omittingEmptySubsequences: false)
    .map { line in
      let lineCount = line.count
      let dropCount = -min(0, 80 - lineCount)
      var truncatedLine = line.dropLast(dropCount)
      if dropCount != 0 {
        truncatedLine += "..."
      }
      return truncatedLine
    }
    .map { " " + $0 }

  lines = lines
    .enumerated()
    .map { index, line in
      let isFirst = index == 0
      let isLast = index == lines.count - 1
      let prefix = isFirst || (isLast && children.isEmpty) ? "*" : "|"
      return prefix + line
    }

  let childrenLines = children
    .enumerated()
    .flatMap { childIndex, child in
      let isLastChild = childIndex == children.count - 1
      var childLines = ["|"]
      childLines += logLines(for: child, header: nil)
        .enumerated()
        .map { index, line in
          let prefix = index == 0 ? "*" : isLastChild ? " " : "|"
          return prefix + line
        }
      return childLines
    }

  return [lines, childrenLines]
    .flatMap { $0 }
    .enumerated()
    .map { index, line in
      let prefix = index == 0 && header == nil ? "-" : " "
      return prefix + line
    }
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
