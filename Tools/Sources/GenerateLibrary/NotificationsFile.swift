// Copyright © 2022 foxacid7cd. All rights reserved.

import Foundation
import MessagePack
import SwiftSyntax
import SwiftSyntaxBuilder

public struct NotificationsFile: GeneratableFile {
  public init(_ metadata: Metadata) {
    self.metadata = metadata
  }

  public var metadata: Metadata

  public var name: String {
    "Notifications"
  }

  public var sourceFile: SourceFile {
    .init {
      "import MessagePack" as ImportDecl

      EnumDecl("public enum Notifications") {
        for uiEvent in metadata.uiEvents {
          let classInSignature = uiEvent.name
            .camelCased
            .capitalized

          ClassDecl(
            "class \(classInSignature)"
          ) {}
        }
      }
    }
  }
}
