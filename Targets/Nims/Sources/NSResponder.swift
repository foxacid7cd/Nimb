//
//  NSResponder.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 19.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import RxSwift

extension NSResponder {
  var store: Store {
    .shared
  }

  @MainActor
  var state: State {
    self.store.state
  }

  var stateChanges: Observable<[StateChange]> {
    self.store.stateChanges
  }
}
