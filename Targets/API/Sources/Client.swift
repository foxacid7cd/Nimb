//
//  Client.swift
//
//
//  Created by Yevhenii Matviienko on 29.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import Library
import MessagePack
import Procedures

public class Client {
  let process: ProceduringProcess

  @MainActor
  public init() {
    self.process = .init(
      executableURL: URL(fileURLWithPath: "/bin/zsh"),
      arguments: ["-c", "nvim --embed"]
    )
  }
}
