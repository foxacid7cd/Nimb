// SPDX-License-Identifier: MIT

import AppKit
import NimbCore
import NimbNeovim
import NimbState

public class MainWindowController: NSWindowController, Rendering {
  private class CustomWindow: NSWindow {
    override var canBecomeMain: Bool {
      true
    }

    override var canBecomeKey: Bool {
      true
    }
  }

  public var renderContext: RenderContext! = nil

  private let store: Store
  private let customWindow = CustomWindow(
    contentRect: .init(),
    styleMask: [.titled, .miniaturizable, .fullSizeContentView],
    backing: .buffered,
    defer: true,
  )
  private let viewController: MainViewController
  private var isWindowInitiallyShown = false

  public init(
    store: Store,
    minOuterGridSize: IntegerSize,
  ) {
    self.store = store
    viewController = .init(
      store: store,
      minOuterGridSize: minOuterGridSize,
    )
    customWindow.contentViewController = viewController
    customWindow.titlebarAppearsTransparent = true
    customWindow.title = ""
    customWindow.isMovable = false
    customWindow.isOpaque = false
    customWindow.backgroundColor = .clear
    customWindow.allowsConcurrentViewDrawing = true
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
    if updates.isAppearanceUpdated {
      let backgroundColor = state.appearance.defaultBackgroundColor
      customWindow.isOpaque = backgroundColor.alpha == 1
      customWindow.backgroundColor = backgroundColor.appKit
    }

    renderChildren(viewController)

    if !isWindowInitiallyShown, let outerGrid = state.outerGrid {
      isWindowInitiallyShown = true

      Task { @MainActor in
        let contentSize = UserDefaults.standard.savedWindowGeometry?.contentSize ?? viewController
          .estimatedContentSize(outerGridSize: outerGrid.size)
        customWindow.setContentSize(contentSize)
        customWindow.makeMain()
        customWindow.makeKeyAndOrderFront(nil)
      }
    }
  }

  public func saveWindowGeometry(outerGridSize: IntegerSize) {
    guard
      isWindowInitiallyShown,
      !customWindow.inLiveResize,
      let contentSize = customWindow.contentView?.frame.size
    else {
      return
    }
    UserDefaults.standard.savedWindowGeometry = .init(
      contentSize: contentSize,
      outerGridSize: outerGridSize,
    )
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
  public func windowDidBecomeKey(_: Notification) {
    store.dispatch(Actions.SetWindowKey(value: true))
  }

  public func windowDidResignKey(_: Notification) {
    store.dispatch(Actions.SetWindowKey(value: false))
  }

  public func windowDidResize(_: Notification) {
    if isWindowInitiallyShown {
      let outerGridSize = viewController.reportOuterGridSizeChanged()
      if !customWindow.inLiveResize {
        saveWindowGeometry(outerGridSize: outerGridSize)
      }
    }
  }

  public func windowDidEndLiveResize(_: Notification) {
    saveWindowGeometry(
      outerGridSize: viewController.reportOuterGridSizeChanged(),
    )
  }
}
