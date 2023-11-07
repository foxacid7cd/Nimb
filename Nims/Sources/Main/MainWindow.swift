// SPDX-License-Identifier: MIT

import AppKit
import Library

public class MainWindow: NSWindow {
  public init(store: Store, minOuterGridSize: IntegerSize) {
    self.store = store
    mainViewController = .init(
      store: store,
      minOuterGridSize: minOuterGridSize
    )
    super.init(
      contentRect: .init(),
      styleMask: [.titled, .miniaturizable, .fullSizeContentView],
      backing: .buffered,
      defer: true
    )
    contentViewController = mainViewController
    titlebarAppearsTransparent = true
    title = ""
    renderBackgroundColor()
    renderIsMouseOn()
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

    if stateUpdates.isMouseOnUpdated {
      renderIsMouseOn()
    }

    mainViewController.render(stateUpdates)
  }

  public func reportOuterGridSizeChanged() {
    mainViewController.reportOuterGridSizeChanged()
  }

  public func estimatedContentSize(outerGridSize: IntegerSize) -> CGSize {
    mainViewController.estimatedContentSize(outerGridSize: outerGridSize)
  }

  public func screenFrame(forGridID gridID: Grid.ID, gridFrame: IntegerRectangle) -> CGRect? {
    mainViewController.windowFrame(forGridID: gridID, gridFrame: gridFrame)
      .map { convertToScreen($0) }
  }

  private let store: Store
  private let mainViewController: MainViewController

  private func renderBackgroundColor() {
    backgroundColor = store.state.appearance.defaultBackgroundColor.appKit
  }

  private func renderIsMouseOn() {
    if store.state.isMouseOn {
      styleMask.insert(.resizable)
    } else {
      styleMask.remove(.resizable)
    }
  }
}
