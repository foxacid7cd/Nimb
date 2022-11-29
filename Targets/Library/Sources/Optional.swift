//
//  Optional.swift
//  Library
//
//  Created by Yevhenii Matviienko on 18.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public extension Optional {
  var logDescription: String {
    map { "\($0)" } ?? "nil"
  }
}
