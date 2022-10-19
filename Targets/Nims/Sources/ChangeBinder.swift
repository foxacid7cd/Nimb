//
//  ChangeBinder.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 19.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Foundation
import RxSwift

struct ChangeBinder<Change> {
  init(target: NSObject, store: Store, changes: Observable<[Change]>) {
    self.target = target
    self.store = store
    self.changes = changes
  }

  func compactMap<SubChange>(_ transform: @escaping (Change) -> SubChange?) -> ChangeBinder<SubChange> {
    .init(
      target: self.target,
      store: self.store,
      changes: self.changes
        .compactMap { changes in
          let transformed = changes
            .compactMap(transform)

          guard !transformed.isEmpty else {
            return nil
          }

          return transformed
        }
    )
  }

  func filter(_ isIncluded: @escaping ([Change]) -> Bool) -> ChangeBinder<Change> {
    .init(
      target: self.target,
      store: self.store,
      changes: self.changes
        .filter(isIncluded)
    )
  }

  func bind(_ notify: @escaping (_ store: Store, _ changes: [Change]) -> Void) {
    self.changes
      .subscribe(onNext: { notify(store, $0) })
      .disposed(by: self.target.associatedDisposeBag)
  }

  func bindFlat(_ notify: @escaping (_ store: Store, _ change: Change) -> Void) {
    self.bind { store, changes in
      changes.forEach { notify(store, $0) }
    }
  }

  private var target: NSObject
  private var store: Store
  private var changes: Observable<[Change]>
}
