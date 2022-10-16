//
//  Stepper.swift
//  Library
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public struct Stepper {
  public init() {}

  public mutating func next() -> UInt {
    let step = self.step.map { $0 + 1 } ?? 0
    self.step = step

    return step
  }

  private var step: UInt?
}

extension Stepper: RequestIDFactory {
  @MainActor
  public mutating func makeRequestID() -> UInt {
    self.next()
  }
}
