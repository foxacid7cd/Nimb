//
//  AssociatedDisposeBag.swift
//  Library
//
//  Created by Yevhenii Matviienko on 18.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import RxSwift

private let AssociatedDisposeBagKey = "foxacid7cd.Nims.associatedDisposeBag"

public extension NSObject {
  var associatedDisposeBag: DisposeBag {
    if let disposeBag = objc_getAssociatedObject(self, AssociatedDisposeBagKey) as? DisposeBag {
      return disposeBag
    } else {
      let disposeBag = DisposeBag()
      objc_setAssociatedObject(self, AssociatedDisposeBagKey, disposeBag, .OBJC_ASSOCIATION_RETAIN)
      return disposeBag
    }
  }
}
