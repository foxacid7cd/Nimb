// SPDX-License-Identifier: MIT

import AppKit
import Library

final class MainWindowController: NSWindowController {
  init(store: Store) {
    self.store = store
    viewController = MainViewController(
      store: store,
      minOuterGridSize: .init(columnsCount: 80, rowsCount: 24)
    )

    let window = NimsNSWindow(contentViewController: viewController)
    window.styleMask = [.titled, .miniaturizable, .resizable, .fullSizeContentView]
    window.titlebarAppearsTransparent = true
    window.isMovable = false

    super.init(window: window)

    window.delegate = self
    window.title = ""
    windowFrameAutosaveName = "MainWindow"
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func windowDidLoad() {
    super.windowDidLoad()

    updateWindow()
  }

  func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isAppearanceUpdated {
      updateWindow()
    }

    viewController.render(stateUpdates)

    if !isWindowInitiallyShown, stateUpdates.isOuterGridLayoutUpdated, let outerGrid = store.state.outerGrid {
      let contentSize: CGSize = if
        let lastWindowWidth = UserDefaults.standard.value(forKey: "windowWidth") as? Double,
        let lastWindowHeight = UserDefaults.standard.value(forKey: "windowHeight") as? Double
      {
        .init(width: lastWindowWidth, height: lastWindowHeight)
      } else {
        viewController.estimatedContentSize(outerGridSize: outerGrid.size)
      }
      window!.setContentSize(contentSize)

      showWindow(nil)
      isWindowInitiallyShown = true
    }
  }

  func point(forGridID gridID: Grid.ID, gridPoint: IntegerPoint) -> CGPoint? {
    viewController.point(forGridID: gridID, gridPoint: gridPoint)
      .map { $0 + window!.frame.origin }
  }

  private let store: Store
  private let viewController: MainViewController
  private var isWindowInitiallyShown = false

  private func updateWindow() {
    window!.backgroundColor = store.state.appearance.defaultBackgroundColor.appKit
  }

  private func windowFrameManuallyChanged() async {
    await viewController.reportOuterGridSizeChangedIfNeeded()
    UserDefaults.standard.setValue(window!.frame.width, forKey: "windowWidth")
    UserDefaults.standard.setValue(window!.frame.height, forKey: "windowHeight")
  }
}

extension MainWindowController: NSWindowDelegate {
  func windowDidResize(_: Notification) {
    if isWindowInitiallyShown, !window!.inLiveResize {
      Task {
        await windowFrameManuallyChanged()
      }
    }
  }

  func windowWillStartLiveResize(_: Notification) {
    viewController.showMainView(on: false)
  }

  func windowDidEndLiveResize(_: Notification) {
    Task {
      await windowFrameManuallyChanged()
      viewController.showMainView(on: true)
    }
  }
}
