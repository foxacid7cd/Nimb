//
//  Fail.swift
//  Library
//
//  Created by Yevhenii Matviienko on 14.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import OSLog

public struct Fail: Error {
  public init(_ content: Content, children: [Fail] = []) {
    self.content = content
    self.children = children
  }

  public init(_ content: Content, child: Fail? = nil) {
    self.init(content, children: child.map { [$0] } ?? [])
  }

  public enum Content: CustomStringConvertible {
    case details(String)
    case wrapped(Error)

    public var description: String {
      switch self {
      case let .details(details):
        var text = details
          .trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = text.first, first.isLowercase {
          text = first.uppercased() + text.dropFirst()
        }
        if text.last != "." {
          text += "."
        }
        return text

      case let .wrapped(error):
        return String(describing: error)
      }
    }
  }

  public var content: Content
  public var children: [Fail]

  public func fatalError(file: StaticString = #fileID, line: UInt = #line) -> Never {
    print()
    Swift.fatalError("\n\n" + String(loggable: self) + "\n", file: file, line: line)
  }

  public func assertionFailure(file: StaticString = #fileID, line: UInt = #line) {
    print()
    Swift.assertionFailure("\n\n" + String(loggable: self) + "\n", file: file, line: line)
  }
}

public extension StringProtocol {
  func fail(child: Fail? = nil) -> Fail {
    .init(.details(String(self)), child: child)
  }
}

public extension Error {
  func fail(child: Fail? = nil) -> Fail {
    Fail(.wrapped(self), child: child)
  }

  func log(_ logLevel: OSLogType = .error, log: OSLog = .default) {
    Library.log(logLevel, log: log, self)
  }
}

extension Fail: CustomLoggable {
  public var logMessage: String {
    "\(self.content)"
  }

  public var logChildren: [Any] {
    self.children
  }
}
