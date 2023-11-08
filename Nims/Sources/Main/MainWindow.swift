// SPDX-License-Identifier: MIT

import AppKit
import Library

public class MainWindow: NSWindow {
  public init(store: Store, minOuterGridSize: IntegerSize) {
    self.store = store
    viewController = .init(
      store: store,
      minOuterGridSize: minOuterGridSize
    )
    super.init(
      contentRect: .init(),
      styleMask: [.titled, .miniaturizable, .fullSizeContentView],
      backing: .buffered,
      defer: true
    )
    contentViewController = viewController
    titlebarAppearsTransparent = true
    title = ""
    renderBackgroundColor()
    renderIsMouseUserInteractionEnabled()
  }

  override public var canBecomeMain: Bool {
    true
  }

  override public var canBecomeKey: Bool {
    true
  }

  override public func keyDown(with event: NSEvent) {
    let keyPress = KeyPress(event: event)
    Task {
      await store.report(keyPress: keyPress)
    }
  }

  public func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isAppearanceUpdated {
      renderBackgroundColor()
    }

    if stateUpdates.isMouseUserInteractionEnabledUpdated {
      renderIsMouseUserInteractionEnabled()
    }

    viewController.render(stateUpdates)
  }

  public func reportOuterGridSizeChanged() {
    viewController.reportOuterGridSizeChanged()
  }

  public func estimatedContentSize(outerGridSize: IntegerSize) -> CGSize {
    viewController.estimatedContentSize(outerGridSize: outerGridSize)
  }

  public func screenFrame(forGridID gridID: Grid.ID, gridFrame: IntegerRectangle) -> CGRect? {
    viewController.windowFrame(forGridID: gridID, gridFrame: gridFrame)
      .map { convertToScreen($0) }
  }

  private let store: Store
  private let viewController: MainViewController

  private func renderBackgroundColor() {
    backgroundColor = store.state.appearance.defaultBackgroundColor.appKit
  }

  private func renderIsMouseUserInteractionEnabled() {
    if store.state.isMouseUserInteractionEnabled {
      styleMask.insert(.resizable)
    } else {
      styleMask.remove(.resizable)
    }
  }
}
