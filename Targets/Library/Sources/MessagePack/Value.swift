//
//  Value.swift
//  Library
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import MessagePack
import RxSwift

public typealias Value = MessagePackValue

public extension Value {
  var data: Data {
    pack(self)
  }
}

public enum ValueParsingResult {
  case success(value: Value, remainder: Data)
  case insufficientData
}

public extension Data {
  func parseValue() throws -> ValueParsingResult {
    do {
      let (value, remainder) = try unpack(self)
      return .success(value: value, remainder: remainder)

    } catch MessagePackError.insufficientData {
      return .insufficientData

    } catch {
      "failed parsing value"
        .fail(child: error.fail())
        .fatal()
    }
  }
}

public extension ObservableType where Element == Data {
  func unpack() -> Observable<Value> {
    .create { observer in
      var bufferData = Data()

      return self.subscribe(onNext: { data in
        bufferData += data

        do {
          while true {
            let value: Value
            (value, bufferData) = try MessagePack.unpack(bufferData)
            observer.onNext(value)
          }

        } catch MessagePackError.insufficientData {
          return

        } catch {
          "failed parsing data"
            .fail(child: error.fail())
            .fatal()
        }
      })
    }
  }
}

extension Value: Error {}
