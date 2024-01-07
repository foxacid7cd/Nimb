// SPDX-License-Identifier: MIT

import AppKit
import Library

public class MainViewController: NSViewController {
  init(store: Store, minOuterGridSize: IntegerSize) {
    self.store = store
    self.minOuterGridSize = minOuterGridSize
    gridsView = .init(store: store)
    msgShowsViewController = .init(store: store)
    cmdlinesViewController = .init(store: store)
    popupmenuViewController = .init(
      store: store,
      getGridView: { [gridsView] gridID in
        gridsView.gridView(forGridWithID: gridID)
      },
      getCmdlinesView: { [cmdlinesViewController] in
        cmdlinesViewController.view
      }
    )
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func windowFrame(forGridID gridID: Grid.ID, gridFrame: IntegerRectangle) -> CGRect? {
    gridsView.windowFrame(forGridID: gridID, gridFrame: gridFrame)
  }

  override public func loadView() {
    let view = NSView()

    tablineView.setContentCompressionResistancePriority(.init(rawValue: 900), for: .vertical)
    view.addSubview(tablineView)
    tablineView.topToSuperview()
    tablineView.leading(to: view)
    tablineView.trailing(to: view)

    let tablineDoubleClickGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(handleTablineDoubleClick))
    tablineDoubleClickGestureRecognizer.delaysPrimaryMouseButtonEvents = false
    tablineDoubleClickGestureRecognizer.numberOfClicksRequired = 2
    tablineView.addGestureRecognizer(tablineDoubleClickGestureRecognizer)

    view.addSubview(gridsContainerView)
    gridsContainerView.translatesAutoresizingMaskIntoConstraints = false
    gridsContainerView.clipsToBounds = true
    gridsContainerView.topToBottom(of: tablineView)
    gridsContainerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    gridsContainerView.setContentHuggingPriority(.defaultLow, for: .vertical)
    gridsContainerView.leading(to: view)
    gridsContainerView.trailing(to: view)
    gridsContainerView.bottomToSuperview()

    gridsContainerView.addSubview(gridsView)
    gridsView.centerXToSuperview()
    gridsView.topToSuperview()

    view.addSubview(msgShowsViewController.view)
    msgShowsViewController.view.leading(to: view, offset: 10)
    msgShowsViewController.view.bottomToSuperview(offset: -10)
    addChild(msgShowsViewController)

    view.addSubview(cmdlinesViewController.view)
    cmdlinesViewController.view.centerXToSuperview()
    cmdlinesViewController.view.centerYToSuperview(multiplier: 0.65)
    addChild(cmdlinesViewController)

    popupmenuViewController.willShowPopupmenu = { [weak self] in
      self?.reportPopupmenuPumBounds()
    }
    view.addSubview(popupmenuViewController.view)
    popupmenuViewController.anchorConstraints = [
      popupmenuViewController.view.centerXToSuperview(),
      popupmenuViewController.view.centerYToSuperview(),
    ]
    addChild(popupmenuViewController)

    self.view = view
  }

  override public func viewDidLayout() {
    super.viewDidLayout()

    if let window = view.window {
      let titleBarHeight = window.contentView!.frame.height - window.contentLayoutRect.height
      tablineView.preferredViewHeight = titleBarHeight
    }
  }

  public func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isFontUpdated {
      reportOuterGridSizeChanged()
    }

    tablineView.render(stateUpdates)
    gridsView.render(stateUpdates)

    msgShowsViewController.render(stateUpdates)
    cmdlinesViewController.render(stateUpdates)
    popupmenuViewController.render(stateUpdates)
  }

  public func reportOuterGridSizeChanged() {
    let outerGridSizeNeeded = IntegerSize(
      columnsCount: Int(gridsContainerView.frame.width / store.font.cellWidth),
      rowsCount: Int(gridsContainerView.frame.height / store.font.cellHeight)
    )
    Task {
      await store.reportOuterGrid(changedSizeTo: outerGridSizeNeeded)
    }
  }

  public func estimatedContentSize(outerGridSize: IntegerSize) -> CGSize {
    let mainFrameSize = outerGridSize * store.font.cellSize
    return .init(
      width: mainFrameSize.width,
      height: mainFrameSize.height + tablineView.intrinsicContentSize.height
    )
  }

  let gridsView: GridsView

  private let store: Store
  private let msgShowsViewController: MsgShowsViewController
  private let cmdlinesViewController: CmdlinesViewController
  private let popupmenuViewController: PopupmenuViewController
  private let minOuterGridSize: IntegerSize
  private lazy var tablineView = TablineView(store: store)
  private let gridsContainerView = NSView()
  private var gridsContainerViewFrame: CTFrame?
  private var preMaximizeWindowFrame: CGRect?

  @objc private func handleTablineDoubleClick(_: NSClickGestureRecognizer) {
    guard let window = view.window, let screen = window.screen ?? .main else {
      return
    }

    let isMaximized = window.frame == screen.visibleFrame

    if !isMaximized {
      if window.frame != screen.visibleFrame {
        preMaximizeWindowFrame = window.frame
        window.setFrame(
          screen.visibleFrame,
          display: true,
          animate: false
        )
      }

    } else {
      if let preMaximizeWindowFrame, window.frame != preMaximizeWindowFrame {
        window.setFrame(preMaximizeWindowFrame, display: true, animate: false)
      }
    }
  }

  private func reportPopupmenuPumBounds() {
    view.layoutSubtreeIfNeeded()

    var popupmenuFrame = popupmenuViewController.view.frame
    popupmenuFrame = view.convert(popupmenuFrame, to: gridsContainerView)
    popupmenuFrame = gridsContainerView.convert(popupmenuFrame, to: gridsView)
    popupmenuFrame = popupmenuFrame.applying(gridsView.upsideDownTransform)

    let size = IntegerSize(
      columnsCount: Int(ceil(popupmenuFrame.size.width / store.font.cellWidth)),
      rowsCount: Int(ceil(popupmenuFrame.size.height / store.font.cellHeight))
    )
    let rectangle = IntegerRectangle(
      origin: .init(
        column: Int(popupmenuFrame.origin.x / store.font.cellWidth),
        row: Int(popupmenuFrame.origin.y / store.font.cellHeight)
      ),
      size: size
    )
    Task {
      await store.reportPumBounds(rectangle: rectangle)
    }
  }
}
