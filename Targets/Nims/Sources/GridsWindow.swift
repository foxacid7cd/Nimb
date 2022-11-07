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
  init() {
    super.init(
      contentRect: .init(),
      styleMask: [.titled],
      backing: .buffered,
      defer: true
    )
    self.contentViewController = self.gridsViewController
    self.acceptsMouseMovedEvents = true
  }

  var input: Observable<Input> {
    self.inputSubject
  }

  override var canBecomeKey: Bool {
    true
  }

  func handle(event: Event) {
    self.gridsViewController.handle(event: event)
  }

  override func keyDown(with event: NSEvent) {
    self.inputSubject.onNext(.keyboard(.init(event: event)))
  }

  override func mouseDown(with event: NSEvent) {
    guard event.clickCount >= 1 else { return }

    self.mouseInput(event, event: .button(.left, action: .press))
  }

  override func mouseDragged(with event: NSEvent) {
    self.mouseInput(event, event: .button(.left, action: .drag))
  }

  override func mouseMoved(with event: NSEvent) {
    self.mouseInput(event, event: .move)
  }

  override func rightMouseDown(with event: NSEvent) {
    guard event.clickCount >= 1 else { return }

    self.mouseInput(event, event: .button(.right, action: .press))
  }

  override func rightMouseDragged(with event: NSEvent) {
    self.mouseInput(event, event: .button(.right, action: .drag))
  }

  override func otherMouseDown(with event: NSEvent) {
    guard event.clickCount >= 1 else { return }

    self.mouseInput(event, event: .button(.middle, action: .press))
  }

  override func otherMouseDragged(with event: NSEvent) {
    self.mouseInput(event, event: .button(.middle, action: .drag))
  }

  override func scrollWheel(with event: NSEvent) {
    if abs(event.scrollingDeltaY) > 5 {
      self.mouseInput(event, event: .wheel(action: event.scrollingDeltaY > 0 ? .up : .down))
    }
  }

  private lazy var gridsViewController = GridsViewController()
  private let inputSubject = PublishSubject<Input>()

  private func mouseInput(_ nsEvent: NSEvent, event: MouseInput.Event) {
    let locationInWindow = nsEvent.locationInWindow

    guard let contentView, let gridView = contentView.hitTest(locationInWindow) as? GridView else {
      return
    }

    let locationInView = contentView.convert(locationInWindow, to: gridView)
    let rectangle = CellsGeometry.shared.gridRectangle(
      cellsRect: CellsGeometry.shared.upsideDownRect(
        from: .init(origin: locationInView, size: .zero),
        parentViewHeight: gridView.bounds.height
      )
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
