//
//  Stepper.swift
//  Library
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

public actor Stepper {
  public init() {}

  public func next() -> UInt {
    let step = self.step.map { $0 + 1 } ?? 0
    self.step = step

    return step
  }

  private var step: UInt?
}
