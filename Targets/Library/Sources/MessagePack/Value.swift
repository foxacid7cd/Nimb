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

public extension Data {
  func parseValues() throws -> (values: [Value], remainder: Data) {
    var subdata = Subdata(data: self)
    var parsedValues = [Value]()

    do {
      while true {
        let value: Value
        (value, subdata) = try unpack(subdata)
        parsedValues.append(value)
      }

    } catch MessagePackError.insufficientData {
      return (parsedValues, subdata.data)

    } catch {
      throw "failed parsing values"
        .fail(child: error.fail())
    }
  }
}

public extension ObservableType where Element == Data {
  func unpack() -> Observable<[Value]> {
    .create { observer in
      var bufferData = Data()

      return self.subscribe(
        onNext: { data in
          bufferData += data

          do {
            let values: [Value]
            (values, bufferData) = try bufferData.parseValues()
            observer.onNext(values)

          } catch {
            observer.onError(
              "failed parsing values".fail(child: error.fail())
            )
          }
        },
        onError: observer.onError,
        onCompleted: observer.onCompleted
      )
    }
  }
}

extension Value: Error {}
