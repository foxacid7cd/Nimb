//
//  Fail.swift
//  Library
//
//  Created by Yevhenii Matviienko on 14.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import OSLog

public struct Fail: Error, CustomStringConvertible {
  public enum Content: CustomStringConvertible {
    case details(String)
    case wrapped(Error)

    public var description: String {
      switch self {
      case let .details(details):
        return details

      case let .wrapped(error):
        return String(describing: error)
      }
    }
  }

  public var content: Content
  public var children: [Fail]
  public var file: StaticString
  public var line: UInt

  public init(_ content: Content, children: [Fail] = [], file: StaticString = #file, line: UInt = #line) {
    self.content = content
    self.children = children
    self.file = file
    self.line = line
  }

  public init(_ content: Content, child: Fail? = nil, file: StaticString = #file, line: UInt = #line) {
    self.init(content, children: child.map { [$0] } ?? [], file: file, line: line)
  }

  public var description: String {
    let fileName = URL(fileURLWithPath: file.description).lastPathComponent
    let lines = [
      ["\n *--> \(fileName):\(line)"],
      content.description
        .split(separator: "\n")
        .map { " |\($0)" },
      children.map { child in
        let lines = child.description
          .split(separator: "\n", omittingEmptySubsequences: false)

        let formattedLines = lines
          .enumerated()
          .map { index, line in
            let prefix = index == lines.count - 1 ? "-*-" : " | "
            return prefix + line
          }

        return formattedLines
          .joined(separator: "\n")
      },
      children.isEmpty ? ["-*>"] : []
    ]
    .flatMap { $0 }

    return lines
      .joined(separator: "\n")
  }

  public func fatal() -> Never {
    fatalError("\(self)", file: file, line: line)
  }

  public func failAssertion() {
    assertionFailure("\(self)", file: file, line: line)
  }
}

public extension StringProtocol {
  func fail(child: Fail? = nil, file: StaticString = #file, line: UInt = #line) -> Fail {
    .init(.details(String(self)), child: child, file: file, line: line)
  }
}

public extension Error {
  func fail(child: Fail? = nil, file: StaticString = #file, line: UInt = #line) -> Fail {
    Fail(.wrapped(self), child: child, file: file, line: line)
  }

  func log(_ logLevel: OSLogType = .error) {
    Library.log(logLevel, self)
  }
}
