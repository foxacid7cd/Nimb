// SPDX-License-Identifier: MIT

import AppKit

public class MainViewController: NSViewController, Rendering {
  let gridsView: GridsView

  private let store: Store
  private let cmdlinesViewController: CmdlinesViewController
  private let popupmenuViewController: PopupmenuViewController
  private let minOuterGridSize: IntegerSize
  private lazy var tablineView = TablineView(store: store)
  private lazy var gridsContainerView = NSView()
  private var preMaximizeWindowFrame: CGRect?
  private lazy var modalOverlayView = NSView()

  init(store: Store, minOuterGridSize: IntegerSize) {
    self.store = store
    self.minOuterGridSize = minOuterGridSize
    gridsView = .init(store: store)
    cmdlinesViewController = .init(store: store)
    popupmenuViewController = .init(
      store: store,
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

  override public func loadView() {
    let view = NSView()
    view.wantsLayer = true

    //    let visualEffectView = NSVisualEffectView()
    //    visualEffectView.blendingMode = .withinWindow
    //    visualEffectView.material = .titlebar

    //    visualEffectView.translatesAutoresizingMaskIntoConstraints = false
    //    view.addSubview(visualEffectView)
    //    visualEffectView.topToSuperview()
    //    visualEffectView.leading(to: view)
    //    visualEffectView.trailing(to: view)

    tablineView.setContentCompressionResistancePriority(
      .init(rawValue: 900),
      for: .vertical
    )
    view.addSubview(tablineView)
    tablineView.topToSuperview()
    tablineView.leading(to: view)
    tablineView.trailing(to: view)

    let tablineDoubleClickGestureRecognizer = NSClickGestureRecognizer(
      target: self,
      action: #selector(handleTablineDoubleClick)
    )
    tablineDoubleClickGestureRecognizer.delaysPrimaryMouseButtonEvents = false
    tablineDoubleClickGestureRecognizer.numberOfClicksRequired = 2
    tablineView.addGestureRecognizer(tablineDoubleClickGestureRecognizer)

    let topSeparatorView = NSView()
    view.addSubview(topSeparatorView)
    topSeparatorView.topToBottom(of: tablineView)
    topSeparatorView.leading(to: view)
    topSeparatorView.trailing(to: view)
    topSeparatorView.height(1)
    topSeparatorView.wantsLayer = true
    topSeparatorView.layer!.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor

    view.addSubview(
      gridsContainerView,
      positioned: .below,
      relativeTo: tablineView
    )
    gridsContainerView.translatesAutoresizingMaskIntoConstraints = false
    gridsContainerView.clipsToBounds = true
    gridsContainerView.topToBottom(of: topSeparatorView)
    gridsContainerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    gridsContainerView.setContentHuggingPriority(.defaultLow, for: .vertical)
    gridsContainerView.leading(to: view)
    gridsContainerView.trailing(to: view)
    gridsContainerView.bottomToSuperview()

    gridsContainerView.addSubview(gridsView)
    gridsView.centerXToSuperview()
    gridsView.topToSuperview()

    modalOverlayView.wantsLayer = true
    modalOverlayView.layer!.backgroundColor = NSColor.black
      .withAlphaComponent(0.25)
      .cgColor
    modalOverlayView.isHidden = true
    view.addSubview(modalOverlayView)
    modalOverlayView.edgesToSuperview()

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
      let titleBarHeight = window.contentView!.frame.height - window
        .contentLayoutRect.height
      tablineView.preferredViewHeight = titleBarHeight
    }
  }

  public func render() {
    if updates.isFontUpdated {
      reportOuterGridSizeChanged()
    }

    if updates.isAppearanceUpdated {
      renderBackground()
    }

    renderChildren(gridsView, tablineView)

    if updates.isCmdlinesUpdated {
      modalOverlayView.isHidden = state
        .cmdlines.dictionary
        .isEmpty
    }

    renderChildren(cmdlinesViewController, popupmenuViewController)
  }

  public func windowFrame(
    forGridID gridID: Grid.ID,
    gridFrame: IntegerRectangle
  )
    -> CGRect?
  {
    gridsView.windowFrame(forGridID: gridID, gridFrame: gridFrame)
  }

  public func reportOuterGridSizeChanged() {
    let outerGridSizeNeeded = IntegerSize(
      columnsCount: Int(gridsContainerView.frame.width / state.font.cellWidth),
      rowsCount: Int(gridsContainerView.frame.height / state.font.cellHeight)
    )
    store.reportOuterGrid(changedSizeTo: outerGridSizeNeeded)
  }

  public func estimatedContentSize(outerGridSize: IntegerSize) -> CGSize {
    let mainFrameSize = outerGridSize * state.font.cellSize
    return .init(
      width: mainFrameSize.width,
      height: mainFrameSize.height + tablineView.intrinsicContentSize.height
    )
  }

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
    popupmenuFrame = view.convert(popupmenuFrame, to: nil)
    popupmenuFrame = gridsView.convert(popupmenuFrame, from: nil)
    popupmenuFrame = popupmenuFrame.applying(gridsView.upsideDownTransform)
    store.reportPumBounds(rectangle: .init(
      frame: popupmenuFrame,
      cellSize: state.font.cellSize
    ))
  }

  private func renderBackground() {
    view.layer!.backgroundColor = state.appearance.defaultBackgroundColor.appKit.cgColor
  }
}
