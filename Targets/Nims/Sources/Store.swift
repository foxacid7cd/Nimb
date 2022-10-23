//
//  Store.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import CasePaths
import Library
import RxSwift

class Store {
  static let shared = Store()

  private(set) lazy var stateDerivatives = StateDerivatives(store: self)

  @MainActor
  private(set) var state = State()

  var stateChanges: Observable<[StateChange]> {
    self.stateChangesSubject
  }

  @MainActor
  func dispatch(action: (inout State) -> [StateChange]) {
    let stateChanges = action(&self.state)
    self.stateChangesSubject.onNext(stateChanges)
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
        return .monospacedSystemFont(ofSize: size, weight: .init(rawValue: weight))

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

extension Observable where Element == [StateChange] {
  func extract<T>(_ transform: @escaping (StateChange) -> T?) -> Observable<T> {
    self.flatMap {
      Observable<T>.from($0.compactMap(transform))
    }
  }
}
