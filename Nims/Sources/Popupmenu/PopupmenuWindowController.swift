// SPDX-License-Identifier: MIT

import AppKit
import Library

public final class PopupmenuWindowController: NSWindowController {
  public init(
    store: Store,
    mainWindowController: MainWindowController,
    cmdlinesWindowController: CmdlinesWindowController
  ) {
    self.store = store
    self.mainWindowController = mainWindowController
    self.cmdlinesWindowController = cmdlinesWindowController
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
      updateWindowFrame()
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
  private let viewController: PopupmenuViewController
  private var task: Task<Void, Never>?
  private var isVisibleAnimatedOn: Bool?

  private var preferredWindowFrameSize: CGSize? {
    guard let popupmenu = store.state.popupmenu else {
      return nil
    }
    let width: Double = switch popupmenu.anchor {
    case .cmdline:
      cmdlinesWindowController.window!.frame.width
    case .grid:
      300
    }
    return .init(width: width, height: 176)
  }

  private var preferredWindowFrameOrigin: CGPoint? {
    guard let popupmenu = store.state.popupmenu, let preferredWindowFrameSize else {
      return nil
    }
    let anchorFrame: CGRect? = switch popupmenu.anchor {
    case let .grid(id, origin):
      mainWindowController.screenFrame(
        forGridID: id,
        gridFrame: .init(origin: origin, size: .init(columnsCount: 1, rowsCount: 1))
      )
      .map { $0.offsetBy(dx: -13, dy: -2) }
    case .cmdline:
      cmdlinesWindowController.window!.frame.offsetBy(dx: 0, dy: -8)
    }
    guard let anchorFrame else {
      return nil
    }
    return .init(
      x: anchorFrame.origin.x,
      y: anchorFrame.origin.y - preferredWindowFrameSize.height
    )
  }

  private var preferredWindowFrame: CGRect? {
    guard let preferredWindowFrameOrigin, let preferredWindowFrameSize else {
      return nil
    }
    return .init(origin: preferredWindowFrameOrigin, size: preferredWindowFrameSize)
  }

  private func updateWindowFrame() {
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
