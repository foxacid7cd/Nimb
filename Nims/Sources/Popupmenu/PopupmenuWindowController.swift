// SPDX-License-Identifier: MIT

import AppKit
import Library

@MainActor
public protocol GridWindowFrameTransformer: AnyObject {
  func anchorOrigin(for anchor: Popupmenu.Anchor) -> CGPoint?
}

public final class PopupmenuWindowController: NSWindowController {
  public init(
    store: Store,
    mainWindow: NSWindow,
    cmdlinesWindow: NSWindow,
    msgShowsWindow: NSWindow,
    gridWindowFrameTransformer: GridWindowFrameTransformer
  ) {
    self.store = store
    self.mainWindow = mainWindow
    self.cmdlinesWindow = cmdlinesWindow
    self.msgShowsWindow = msgShowsWindow
    self.gridWindowFrameTransformer = gridWindowFrameTransformer
    viewController = .init(store: store)

    let window = NimsNSWindow(contentViewController: viewController)
    window._canBecomeKey = false
    window._canBecomeMain = false
    window.styleMask = [.titled, .fullSizeContentView]
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovable = false
    window.isOpaque = false
    window.setIsVisible(false)

    super.init(window: window)

    updateWindow()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isPopupmenuUpdated || stateUpdates.isAppearanceUpdated || stateUpdates.isFontUpdated {
      updateWindow()

    } else if stateUpdates.isPopupmenuSelectionUpdated {
      viewController.reloadData()

      if let selectedItemIndex = store.state.popupmenu?.selectedItemIndex {
        viewController.scrollTo(itemAtIndex: selectedItemIndex)
      }
    }
  }

  private let store: Store
  private let mainWindow: NSWindow
  private let cmdlinesWindow: NSWindow
  private let msgShowsWindow: NSWindow
  private weak var gridWindowFrameTransformer: GridWindowFrameTransformer?
  private let viewController: PopupmenuViewController
  private var task: Task<Void, Never>?

  private func updateWindow() {
    if let popupmenu = store.state.popupmenu, let outerGrid = store.state.outerGrid {
      viewController.reloadData()

      if let anchorOrigin = gridWindowFrameTransformer?.anchorOrigin(for: popupmenu.anchor) {
        let size = CGSize(
          width: 300,
          height: 176
        )
        let origin = CGPoint(
          x: anchorOrigin.x - 13,
          y: anchorOrigin.y - size.height
        )
        let windowFrame = CGRect(origin: origin, size: size)

        let gridSize = CGSize(
          width: ceil(size.width / store.font.cellWidth),
          height: ceil(size.height / store.font.cellHeight)
        )
        let gridFrame = CGRect(
          origin: .init(
            x: floor((origin.x - mainWindow.frame.origin.x) / store.font.cellWidth),
            y: Double(outerGrid.rowsCount) - floor((origin.y - mainWindow.frame.origin.y) / store.font.cellHeight) - gridSize.height
          ),
          size: gridSize
        )

        Task {
          await store.reportPumBounds(gridFrame: gridFrame)
        }

        let parentWindow = switch popupmenu.anchor {
        case .grid:
          mainWindow

        case .cmdline:
          cmdlinesWindow
        }

        window!.setFrame(windowFrame, display: true)
        parentWindow.addChildWindow(window!, ordered: .above)

        if let selectedItemIndex = popupmenu.selectedItemIndex {
          viewController.scrollTo(itemAtIndex: selectedItemIndex)
        }
      }

    } else {
      window!.parent?.removeChildWindow(window!)
      window!.setIsVisible(false)
    }
  }
}
