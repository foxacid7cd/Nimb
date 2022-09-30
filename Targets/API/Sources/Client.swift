//
//  Client.swift
//
//
//  Created by Yevhenii Matviienko on 29.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Procedures

@MainActor
public class Client {
  private let procedureExecutor: ProcedureExecutor

  public init(procedureExecutor: ProcedureExecutor) {
    self.procedureExecutor = procedureExecutor
  }

  @discardableResult
  func execute(method: String, parameters: [Value]) async throws -> Value {
    let result = try await procedureExecutor.execute(
      procedure: .init(method: method, params: parameters)
    )
    guard result.isSuccess else {
      throw result.payload
    }
    return result.payload
  }
}
