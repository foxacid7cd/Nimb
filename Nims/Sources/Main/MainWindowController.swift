// SPDX-License-Identifier: MIT

import AppKit
import AsyncAlgorithms
import Library

public final class MainWindowController: NSWindowController {
  public init(store: Store) {
    self.store = store

    let window = MainWindow(
      contentRect: .init(),
      styleMask: [.titled, .miniaturizable, .fullSizeContentView],
      backing: .buffered,
      defer: true
    )
    window.titlebarAppearsTransparent = true
    window.title = ""
    super.init(window: window)

    window.delegate = self
    updateWindow()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func screenFrame(forGridID gridID: Grid.ID, gridFrame: IntegerRectangle) -> CGRect? {
    viewController.windowFrame(forGridID: gridID, gridFrame: gridFrame)
      .map { window!.convertToScreen($0) }
  }

  func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isAppearanceUpdated || stateUpdates.isMouseOnUpdated {
      updateWindow()
    }

    viewController.render(stateUpdates)

    if !isWindowInitiallyShown, stateUpdates.isOuterGridLayoutUpdated, let outerGrid = store.state.outerGrid {
      window!.contentViewController = viewController

      let contentSize: CGSize = if
        let lastWindowWidth = UserDefaults.standard.value(forKey: "windowWidth") as? Double,
        let lastWindowHeight = UserDefaults.standard.value(forKey: "windowHeight") as? Double
      {
        .init(width: lastWindowWidth, height: lastWindowHeight)
      } else {
        viewController.estimatedContentSize(outerGridSize: outerGrid.size)
      }
      window!.setContentSize(contentSize)

      window!.makeKeyAndOrderFront(nil)
      isWindowInitiallyShown = true
    }
  }

  private let store: Store
  private lazy var viewController = MainViewController(
    store: store,
    minOuterGridSize: .init(columnsCount: 80, rowsCount: 24)
  )
  private var isWindowInitiallyShown = false

  private func updateWindow() {
    window!.backgroundColor = store.state.appearance.defaultBackgroundColor.appKit
    if store.state.isMouseOn {
      window!.styleMask.insert(.resizable)
    } else {
      window!.styleMask.remove(.resizable)
    }
  }

  private func saveWindowFrame() {
    UserDefaults.standard.setValue(window!.frame.width, forKey: "windowWidth")
    UserDefaults.standard.setValue(window!.frame.height, forKey: "windowHeight")
  }
}

extension MainWindowController: NSWindowDelegate {
  public func windowDidResize(_: Notification) {
    guard isWindowInitiallyShown else {
      return
    }
    viewController.reportOuterGridSizeChanged()
    if !window!.inLiveResize {
      saveWindowFrame()
    }
  }

  public func windowDidEndLiveResize(_: Notification) {
    viewController.reportOuterGridSizeChanged()
    saveWindowFrame()
  }
}

private final class MainWindow: NSWindow {
  override var canBecomeMain: Bool {
    true
  }

  override var canBecomeKey: Bool {
    true
  }
}
