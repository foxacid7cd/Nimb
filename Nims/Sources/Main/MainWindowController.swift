// SPDX-License-Identifier: MIT

import AppKit
import AsyncAlgorithms
import Library

final class MainWindowController: NSWindowController {
  init(store: Store) {
    self.store = store

    let window = NimsNSWindow(
      contentRect: .init(),
      styleMask: [.titled, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered,
      defer: true
    )
    window.titlebarAppearsTransparent = true
    window.isMovable = false
    window.title = ""
    super.init(window: window)

    window.delegate = self
    windowFrameAutosaveName = "MainWindow"
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  enum Event {
    case liveResizeChanged(on: Bool)
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

      showWindow(nil)
      isWindowInitiallyShown = true
    }
  }

  func point(forGridID gridID: Grid.ID, gridPoint: IntegerPoint) -> CGPoint? {
    viewController.point(forGridID: gridID, gridPoint: gridPoint)
      .map { $0 + .init(x: 0, y: -store.font.cellHeight) }
      .map { window!.convertPoint(toScreen: $0) }
  }

  private let store: Store
  private lazy var viewController = MainViewController(
    store: store,
    minOuterGridSize: .init(columnsCount: 80, rowsCount: 24)
  )
  private var isWindowInitiallyShown = false
  private let eventChannel = AsyncChannel<Event>()

  private func updateWindow() {
    window!.backgroundColor = store.state.appearance.defaultBackgroundColor.appKit
  }

  private func windowFrameManuallyChanged() {
    viewController.reportOuterGridSizeChangedIfNeeded()
    UserDefaults.standard.setValue(window!.frame.width, forKey: "windowWidth")
    UserDefaults.standard.setValue(window!.frame.height, forKey: "windowHeight")
  }
}

extension MainWindowController: NSWindowDelegate {
  func windowDidResize(_: Notification) {
    if isWindowInitiallyShown, !window!.inLiveResize {
      windowFrameManuallyChanged()
    }
  }

  func windowWillStartLiveResize(_: Notification) {
    viewController.showMainView(on: false)
    Task {
      await eventChannel.send(.liveResizeChanged(on: true))
    }
  }

  func windowDidEndLiveResize(_: Notification) {
    windowFrameManuallyChanged()
    viewController.showMainView(on: true)
    Task {
      await eventChannel.send(.liveResizeChanged(on: false))
    }
  }
}

extension MainWindowController: AsyncSequence {
  typealias Element = Event

  nonisolated func makeAsyncIterator() -> AsyncChannel<Event>.AsyncIterator {
    eventChannel.makeAsyncIterator()
  }
}
