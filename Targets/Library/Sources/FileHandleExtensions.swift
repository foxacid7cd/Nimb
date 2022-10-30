//
//  FileHandle+Observable.swift
//  Library
//
//  Created by Yevhenii Matviienko on 16.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import RxSwift

public extension FileHandle {
  var data: Observable<Data> {
    .create { observer in
      self.readabilityHandler = { fileHandle in
        let data = fileHandle.availableData

        guard !data.isEmpty else {
          DispatchQueue.main.async {
            observer.onCompleted()
          }

          return
        }

        DispatchQueue.main.async {
          observer.onNext(data)
        }
      }

      return Disposables.create {
        self.readabilityHandler = nil
      }
    }
  }
}
