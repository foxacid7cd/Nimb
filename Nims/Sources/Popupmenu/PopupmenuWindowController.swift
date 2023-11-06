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

    let window = FloatingPanel(contentViewController: viewController)
    super.init(window: window)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isMouseOnUpdated {
      viewController.setIsUserInteractionEnabled(store.state.isMouseOn)
    }

    if stateUpdates.isPopupmenuUpdated || !stateUpdates.updatedLayoutGridIDs.isEmpty || stateUpdates.isFontUpdated {
      updateWindowFrameIfNeeded()
    }

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
  private var isVisibleAnimatedOn: Bool?

  private var preferredWindowFrame: CGRect {
    guard
      let gridWindowFrameTransformer,
      let popupmenu = store.state.popupmenu,
      let anchorOrigin = gridWindowFrameTransformer.anchorOrigin(for: popupmenu.anchor)
    else {
      return .init()
    }
    let size = CGSize(
      width: 300,
      height: 176
    )
    let origin = CGPoint(
      x: anchorOrigin.x - 13,
      y: anchorOrigin.y - size.height
    )
    return .init(origin: origin, size: size)
  }

  private func updateWindowFrameIfNeeded() {
    guard let outerGrid = store.state.outerGrid else {
      return
    }

    let frame = preferredWindowFrame
    if frame != window!.frame {
      window!.setFrame(frame, display: true)

      let size = IntegerSize(
        columnsCount: Int((frame.size.width / store.font.cellWidth).rounded(.up)),
        rowsCount: Int((frame.size.height / store.font.cellHeight).rounded(.up))
      )
      let rectangle = IntegerRectangle(
        origin: .init(
          column: Int(((frame.origin.x - mainWindow.frame.origin.x) / store.font.cellWidth).rounded(.down)),
          row: outerGrid.rowsCount - Int(((frame.origin.y - mainWindow.frame.origin.y) / store.font.cellHeight).rounded(.down)) - size.rowsCount + 1
        ),
        size: size
      )
      Task {
        await store.reportPumBounds(rectangle: rectangle)
      }
    }
  }

  private func updateWindow() {
    viewController.reloadData()

    if let popupmenu = store.state.popupmenu {
      if window!.parent == nil {
        mainWindow.addChildWindow(window!, ordered: .above)
        window!.alphaValue = 0
      }

      if let selectedItemIndex = popupmenu.selectedItemIndex {
        viewController.scrollTo(itemAtIndex: selectedItemIndex)
      }

      if isVisibleAnimatedOn != true {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.12
          window!.animator().alphaValue = 1
        }
        isVisibleAnimatedOn = true
      }
    } else {
      if isVisibleAnimatedOn != false {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.12
          window!.animator().alphaValue = 0
        }
        isVisibleAnimatedOn = false
      }
    }
  }
}
