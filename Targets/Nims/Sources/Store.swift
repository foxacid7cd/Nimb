//
//  Store.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Library
import RxSwift

class Store {
  static let shared = Store()

  private(set) lazy var stateDerivatives = StateDerivatives(store: self)

  @MainActor
  private(set) var state = State()

  @MainActor
  func bind(to target: NSObject) -> ChangeBinder<StateChange> {
    .init(target: target, store: self, changes: self.stateChangesSubject)
  }

  @MainActor
  func dispatch(action: (inout State) -> [StateChange]) {
    let stateChanges = action(&self.state)
    self.stateChangesSubject.onNext(stateChanges)
  }

  @MainActor
  func dispatch(action: (inout State) -> StateChange?) {
    self.dispatch { state -> [StateChange] in
      [action(&state)]
        .compactMap { $0 }
    }
  }

  private let stateChangesSubject = PublishSubject<[StateChange]>()
}

class StateDerivatives {
  init(store: Store) {
    self.store = store
  }

  struct Font {
    var nsFont: NSFont
    var cellSize: CGSize
  }

  @MainActor
  var font: Font {
    if let (stateFont, font) = latestFontContext, stateFont == self.state.font {
      return font
    }

    let nsFont: NSFont = {
      switch self.state.font {
      case let .monospacedSystem(size, weight):
        return .monospacedSystemFont(ofSize: size, weight: weight)

      case let .custom(name, size):
        return .init(name: name, size: size)!
      }
    }()
    let font = Font(
      nsFont: nsFont,
      cellSize: nsFont.calculateCellSize(for: "@")
    )
    self.latestFontContext = (self.state.font, font)

    return font
  }

  private var latestFontContext: (stateFont: State.Font, font: Font)?
  private let store: Store

  @MainActor
  private var state: State {
    self.store.state
  }
}
