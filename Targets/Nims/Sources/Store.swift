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
      .share(replay: 1, scope: .forever)
  }

  static let shared = Store()

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
  struct Font {
    var regular: NSFont
    var bold: NSFont
    var italic: NSFont
    var boldItalic: NSFont

    var cellSize: CGSize
    var glyphRunCache: Cache<Int, GlyphRun>
  }

  static let shared = StateDerivatives()

  @MainActor
  func font(state: State) -> Font {
    if let cachedFont = self.cachedFonts[state.font] {
      return cachedFont

    } else {
      let regular: NSFont
      let bold: NSFont
      let italic: NSFont
      let boldItalic: NSFont

      switch state.font {
      case let .monospacedSystem(size):
        regular = .monospacedSystemFont(ofSize: size, weight: .regular)
        bold = .monospacedSystemFont(ofSize: size, weight: .bold)
        italic = .monospacedSystemFont(ofSize: size, weight: .regular)
        boldItalic = .monospacedSystemFont(ofSize: size, weight: .bold)

      case let .custom(name, size):
        regular = .init(name: name, size: size)!
        bold = NSFontManager.shared.convert(regular, toHaveTrait: .boldFontMask)
        italic = NSFontManager.shared.convert(regular, toHaveTrait: .italicFontMask)
        boldItalic = NSFontManager.shared.convert(bold, toHaveTrait: .italicFontMask)
      }

      let font = Font(
        regular: regular,
        bold: bold,
        italic: italic,
        boldItalic: boldItalic,
        cellSize: regular.calculateCellSize(for: "@"),
        glyphRunCache: .init(capacity: 4 * 1024)
      )

      self.cachedFonts[state.font] = font
      return font
    }
  }

  @MainActor
  private var cachedFonts = [State.Font: Font]()
}

extension Observable where Element == [Event] {
  func extract<T>(_ transform: @escaping (Event) -> T?) -> Observable<T> {
    self.flatMap {
      Observable<T>.from($0.compactMap(transform))
    }
  }
}
