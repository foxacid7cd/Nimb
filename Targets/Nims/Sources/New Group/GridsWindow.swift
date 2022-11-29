//
//  GridsWindow.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 23.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import API
import AppKit
import Carbon
import Library
import RxSwift

class GridsWindow: NSWindow {
  init(state: State) {
    self.state = state

    let gridsViewController = GridsViewController(state: state)
    self.gridsViewController = gridsViewController

    super.init(
      contentRect: .init(),
      styleMask: [.titled],
      backing: .buffered,
      defer: true
    )
    contentViewController = gridsViewController
    acceptsMouseMovedEvents = true

    self <~ self.mouseMovedSubject
      .throttle(.milliseconds(50), scheduler: MainScheduler.instance)
      .bind(with: self) { $0.mouseInput($1, event: .move) }

    self <~ self.scrollWheelSubject
      .throttle(.milliseconds(50), scheduler: MainScheduler.instance)
      .bind(with: self) { strongSelf, event in
        guard abs(event.scrollingDeltaY) > 5 else { return }

        strongSelf.mouseInput(event, event: .wheel(action: event.scrollingDeltaY > 0 ? .up : .down))
      }
  }

  var input: Observable<Input> {
    self.inputSubject
  }

  override var canBecomeKey: Bool {
    true
  }

  @MainActor
  func handle(state: State, events: [Event]) async {
    self.state = state

    await self.gridsViewController.handle(state: state, events: events)
  }

  override func keyDown(with event: NSEvent) {
    self.inputSubject.onNext(.keyboard(.init(event: event)))
  }

  override func mouseDown(with event: NSEvent) {
    self.mouseInput(event, event: .button(.left, action: .press))
  }

  override func mouseDragged(with event: NSEvent) {
    self.mouseInput(event, event: .button(.left, action: .drag))
  }

  override func mouseUp(with event: NSEvent) {
    self.mouseInput(event, event: .button(.left, action: .release))
  }

  override func mouseMoved(with event: NSEvent) {
    self.mouseMovedSubject.onNext(event)
  }

  override func rightMouseDown(with event: NSEvent) {
    self.mouseInput(event, event: .button(.right, action: .press))
  }

  override func rightMouseDragged(with event: NSEvent) {
    self.mouseInput(event, event: .button(.right, action: .drag))
  }

  override func rightMouseUp(with event: NSEvent) {
    self.mouseInput(event, event: .button(.right, action: .release))
  }

  override func otherMouseDown(with event: NSEvent) {
    self.mouseInput(event, event: .button(.middle, action: .press))
  }

  override func otherMouseDragged(with event: NSEvent) {
    self.mouseInput(event, event: .button(.middle, action: .drag))
  }

  override func otherMouseUp(with event: NSEvent) {
    self.mouseInput(event, event: .button(.middle, action: .release))
  }

  override func scrollWheel(with event: NSEvent) {
    self.scrollWheelSubject.onNext(event)
  }

  @MainActor
  private var state: State
  private let gridsViewController: GridsViewController
  private let mouseMovedSubject = PublishSubject<NSEvent>()
  private let scrollWheelSubject = PublishSubject<NSEvent>()
  private let inputSubject = PublishSubject<Input>()

  private func mouseInput(_ nsEvent: NSEvent, event: MouseInput.Event) {
    let locationInWindow = nsEvent.locationInWindow

    guard let contentView, let gridView = contentView.hitTest(locationInWindow) as? GridView else {
      return
    }

    let locationInView = contentView.convert(locationInWindow, to: gridView)
    let rectangle = CellsGeometry.gridRectangle(
      cellsRect: CellsGeometry.upsideDownRect(
        from: .init(origin: locationInView, size: .zero),
        parentViewHeight: gridView.bounds.height
      ),
      cellSize: self.state.fontDerivatives.cellSize
    )
    self.inputSubject.onNext(
      .mouse(
        .init(
          event: event,
          gridID: gridView.gridID,
          point: rectangle.origin
        )
      )
    )
  }
}
