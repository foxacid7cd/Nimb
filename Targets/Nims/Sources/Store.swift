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
import RxCocoa
import RxSwift

class Store {
  private init() {
    let eventsSubject = PublishSubject<[Event]>()
    self.eventsSubject = eventsSubject

    self.events = eventsSubject
      .filter { !$0.isEmpty }
      .share(replay: 1, scope: .forever)
  }

  static let shared = Store()

  private(set) lazy var stateDerivatives = StateDerivatives(store: self)

  let events: Observable<[Event]>

  var state = State()

  func publish(events: [Event]) {
    self.eventsSubject.onNext(events)
  }

  func publish(event: Event) {
    self.eventsSubject.onNext([event])
  }

  private var eventsSubject = PublishSubject<[Event]>()
}

class StateDerivatives {
  init(store: Store) {
    self.store = store
  }

  struct Font {
    var nsFont: NSFont
    var cellSize: CGSize
    var glyphRunsCache: Cache<[Character], GlyphRun>
  }

  var font: Font {
    if let (stateFont, font) = DispatchQueues.StateDerivatives.sync(execute: { self.latestFontContext }), stateFont == self.state.font {
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
      cellSize: nsFont.calculateCellSize(for: "@"),
      glyphRunsCache: .init(dispatchQueue: DispatchQueues.GlyphRunsCache)
    )
    DispatchQueues.StateDerivatives.async(flags: .barrier) {
      self.latestFontContext = (self.state.font, font)
    }

    return font
  }

  private var latestFontContext: (stateFont: State.Font, font: Font)?
  private let store: Store

  private var state: State {
    self.store.state
  }
}

extension Observable where Element == [Event] {
  func extract<T>(_ transform: @escaping (Event) -> T?) -> Observable<T> {
    self.flatMap {
      Observable<T>.from($0.compactMap(transform))
    }
  }
}
