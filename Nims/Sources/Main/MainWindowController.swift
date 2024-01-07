// SPDX-License-Identifier: MIT

import AppKit
import AsyncAlgorithms
import Library

public class MainWindowController: NSWindowController {
  public init(store: Store, minOuterGridSize: IntegerSize) {
    self.store = store
    mainWindow = MainWindow(store: store, minOuterGridSize: minOuterGridSize)
    super.init(window: mainWindow)

    mainWindow.delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render(_ stateUpdates: State.Updates) {
    mainWindow.render(stateUpdates)

    if !isWindowInitiallyShown, let outerGrid = store.state.outerGrid {
      isWindowInitiallyShown = true

      let contentSize = UserDefaults.standard.lastWindowSize ?? mainWindow.estimatedContentSize(outerGridSize: outerGrid.size)
      mainWindow.setContentSize(contentSize)
      showWindow(nil)
    }
  }

  private let store: Store
  private let mainWindow: MainWindow
  private var isWindowInitiallyShown = false

  private func saveWindowFrame() {
    UserDefaults.standard.lastWindowSize = window!.frame.size
  }
}

extension MainWindowController: NSWindowDelegate {
  public func windowDidResize(_: Notification) {
    guard isWindowInitiallyShown else {
      return
    }
    mainWindow.reportOuterGridSizeChanged()
    if !mainWindow.inLiveResize {
      saveWindowFrame()
    }
  }

  public func windowDidEndLiveResize(_: Notification) {
    mainWindow.reportOuterGridSizeChanged()
    saveWindowFrame()
  }
}
