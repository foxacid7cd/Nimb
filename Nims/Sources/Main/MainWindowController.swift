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

      let contentSize: CGSize = if
        let lastWindowWidth = UserDefaults.standard.value(forKey: "windowWidth") as? Double,
        let lastWindowHeight = UserDefaults.standard.value(forKey: "windowHeight") as? Double
      {
        .init(width: lastWindowWidth, height: lastWindowHeight)
      } else {
        mainWindow.estimatedContentSize(outerGridSize: outerGrid.size)
      }
      mainWindow.setContentSize(contentSize)
      showWindow(nil)
    }
  }

  private let store: Store
  private let mainWindow: MainWindow
  private var isWindowInitiallyShown = false

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
