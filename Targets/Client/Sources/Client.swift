//
//  Client.swift
//
//
//  Created by Yevhenii Matviienko on 29.09.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import MessagePack
import Procedures

public class Client {
  private let procedureExecutor: ProcedureExecutor

  public init(procedureExecutor: ProcedureExecutor) {
    self.procedureExecutor = procedureExecutor
  }

  func execute(method: String, parameters: [MessagePackValue]) async throws -> MessagePackValue {
    let result = try await procedureExecutor.execute(
      procedure: .init(method: method, params: parameters)
    )
    guard result.isSuccess else {
      throw NvimError(payload: result.payload)
    }
    return result.payload
  }
}
