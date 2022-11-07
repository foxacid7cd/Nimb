//
//  RequestIDFactory.swift
//  Library
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public protocol RequestIDFactory {
  mutating func makeRequestID() -> UInt
}
