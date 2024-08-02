// SPDX-License-Identifier: MIT

import AppKit
import AsyncAlgorithms
import Library

public class MainWindowController: NSWindowController {
  public init(store: Store, minOuterGridSize: IntegerSize) {
    self.store = store
    viewController = .init(
      store: store,
      minOuterGridSize: minOuterGridSize
    )
    customWindow.contentViewController = viewController
    customWindow.titlebarAppearsTransparent = true
    customWindow.title = ""
    customWindow.isMovable = false
    customWindow.isOpaque = true
    customWindow.titlebarSeparatorStyle = .shadow
    customWindow.animationBehavior = .documentWindow
    customWindow.backgroundColor = .windowBackgroundColor
    customWindow.keyPressed = { keyPress in
      store.report(keyPress: keyPress)
    }
    super.init(window: customWindow)

    customWindow.delegate = self

    renderBackgroundColor()
    renderIsMouseUserInteractionEnabled()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isAppearanceUpdated {
      renderBackgroundColor()
    }

    if stateUpdates.isMouseUserInteractionEnabledUpdated {
      renderIsMouseUserInteractionEnabled()
    }

    viewController.render(stateUpdates)

    if !isWindowInitiallyShown, let outerGrid = store.state.outerGrid {
      isWindowInitiallyShown = true

      let contentSize = UserDefaults.standard.lastWindowSize ?? viewController
        .estimatedContentSize(outerGridSize: outerGrid.size)
      customWindow.setContentSize(contentSize)
      customWindow.makeKeyAndOrderFront(nil)
    }
  }

  private class CustomWindow: NSWindow {
    var keyPressed: ((KeyPress) -> Void)?

    override var canBecomeMain: Bool {
      true
    }

    override var canBecomeKey: Bool {
      true
    }

    override func keyDown(with event: NSEvent) {
      keyPressed?(.init(event: event))
    }
  }

  private let store: Store
  private let customWindow = CustomWindow(
    contentRect: .init(),
    styleMask: [.titled, .miniaturizable, .fullSizeContentView],
    backing: .buffered,
    defer: true
  )
  private let viewController: MainViewController
  private var isWindowInitiallyShown = false

  private func saveWindowFrame() {
    UserDefaults.standard.lastWindowSize = customWindow.frame.size
  }

  private func renderBackgroundColor() {
//    customWindow.backgroundColor = store.state.appearance.defaultBackgroundColor.appKit
  }

  private func renderIsMouseUserInteractionEnabled() {
    if store.state.isMouseUserInteractionEnabled {
      customWindow.styleMask.insert(.resizable)
    } else {
      customWindow.styleMask.remove(.resizable)
    }
  }
}

extension MainWindowController: NSWindowDelegate {
  public func windowDidResize(_: Notification) {
    if isWindowInitiallyShown {
      viewController.reportOuterGridSizeChanged()
      if !customWindow.inLiveResize {
        saveWindowFrame()
      }
    }
  }

  public func windowDidEndLiveResize(_: Notification) {
    viewController.reportOuterGridSizeChanged()
    saveWindowFrame()
  }
}
