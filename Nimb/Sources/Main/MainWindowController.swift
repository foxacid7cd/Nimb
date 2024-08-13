// SPDX-License-Identifier: MIT

import AppKit

public class MainWindowController: NSWindowController, Rendering {
  private class CustomWindow: NSWindow {
    override var canBecomeMain: Bool {
      true
    }

    override var canBecomeKey: Bool {
      true
    }

    var keyPressed: ((KeyPress) -> Void)?

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

  public init(
    store: Store,
    minOuterGridSize: IntegerSize
  ) {
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
    customWindow.keyPressed = { keyPress in
      try? store.api.keyPressed(keyPress)
    }
    super.init(window: customWindow)

    customWindow.delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render() {
    if updates.isMouseUserInteractionEnabledUpdated {
      renderIsMouseUserInteractionEnabled()
    }

    renderChildren(viewController)

    if !isWindowInitiallyShown, let outerGrid = state.outerGrid {
      isWindowInitiallyShown = true

      let contentSize = UserDefaults.standard.lastWindowSize ?? viewController
        .estimatedContentSize(outerGridSize: outerGrid.size)
      customWindow.setContentSize(contentSize)
      customWindow.makeKeyAndOrderFront(nil)
    }
  }

  private func saveWindowFrame() {
    UserDefaults.standard.lastWindowSize = customWindow.frame.size
  }

  private func renderIsMouseUserInteractionEnabled() {
    if state.isMouseUserInteractionEnabled {
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
