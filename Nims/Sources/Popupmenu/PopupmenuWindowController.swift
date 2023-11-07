// SPDX-License-Identifier: MIT

import AppKit
import Library

public final class PopupmenuWindowController: NSWindowController {
  public init(
    store: Store,
    mainWindowController: MainWindowController,
    cmdlinesWindowController: CmdlinesWindowController,
    msgShowsWindowController: MsgShowsWindowController
  ) {
    self.store = store
    self.mainWindowController = mainWindowController
    self.cmdlinesWindowController = cmdlinesWindowController
    self.msgShowsWindowController = msgShowsWindowController
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
  private let mainWindowController: MainWindowController
  private let cmdlinesWindowController: CmdlinesWindowController
  private let msgShowsWindowController: MsgShowsWindowController
  private let viewController: PopupmenuViewController
  private var task: Task<Void, Never>?
  private var isVisibleAnimatedOn: Bool?

  private let preferredWindowFrameSize = CGSize(
    width: 300,
    height: 176
  )

  private var preferredWindowFrameOrigin: CGPoint? {
    guard let popupmenu = store.state.popupmenu else {
      return nil
    }
    let anchorOrigin: CGPoint? = switch popupmenu.anchor {
    case let .grid(id, origin):
      mainWindowController.screenPoint(forGridID: id, gridPoint: origin)
    case let .cmdline(location):
      cmdlinesWindowController.screenPoint(forCharacterLocation: location)
    }
    guard let anchorOrigin else {
      return nil
    }
    return .init(
      x: anchorOrigin.x - 13,
      y: anchorOrigin.y - preferredWindowFrameSize.height
    )
  }

  private var preferredWindowFrame: CGRect? {
    preferredWindowFrameOrigin.map { .init(origin: $0, size: preferredWindowFrameSize) }
  }

  private func updateWindowFrameIfNeeded() {
    guard let outerGrid = store.state.outerGrid, let frame = preferredWindowFrame else {
      return
    }

    window!.setFrame(frame, display: true)

    let size = IntegerSize(
      columnsCount: Int((frame.size.width / store.font.cellWidth).rounded(.up)),
      rowsCount: Int((frame.size.height / store.font.cellHeight).rounded(.up))
    )
    let rectangle = IntegerRectangle(
      origin: .init(
        column: Int(((frame.origin.x - mainWindowController.window!.frame.origin.x) / store.font.cellWidth).rounded(.down)),
        row: outerGrid.rowsCount - Int(((frame.origin.y - mainWindowController.window!.frame.origin.y) / store.font.cellHeight).rounded(.down)) - size.rowsCount + 1
      ),
      size: size
    )
    Task {
      await store.reportPumBounds(rectangle: rectangle)
    }
  }

  private func updateWindow() {
    viewController.reloadData()

    if let popupmenu = store.state.popupmenu {
      if window!.parent == nil {
        mainWindowController.window!.addChildWindow(window!, ordered: .above)
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
