// SPDX-License-Identifier: MIT

import AppKit
import Library

final class MainViewController: NSViewController {
  init(store: Store, minOuterGridSize: IntegerSize) {
    self.store = store
    self.minOuterGridSize = minOuterGridSize
    tablineView = .init(store: store)
    mainView = .init(store: store)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let stackView = NSStackView(views: [])
    stackView.spacing = 0
    stackView.orientation = .vertical

    tablineView.setContentCompressionResistancePriority(.init(rawValue: 900), for: .vertical)
    stackView.addArrangedSubview(tablineView)

    let tablineDoubleClickGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(handleTablineDoubleClick))
    tablineDoubleClickGestureRecognizer.delaysPrimaryMouseButtonEvents = false
    tablineDoubleClickGestureRecognizer.numberOfClicksRequired = 2
    tablineView.addGestureRecognizer(tablineDoubleClickGestureRecognizer)

    mainContainerView.clipsToBounds = true
    stackView.addArrangedSubview(mainContainerView)

    mainContainerView.addSubview(mainView)

    mainView.centerXToSuperview()
    mainView.topToSuperview()

    mainContainerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    mainContainerView.setContentHuggingPriority(.defaultLow, for: .vertical)
    mainContainerViewConstraints = (
      mainContainerView.width(0, relation: .equalOrGreater),
      mainContainerView.height(0, relation: .equalOrGreater)
    )

    mainOverlayView.blendingMode = .withinWindow
    mainOverlayView.state = .active
    mainOverlayView.isHidden = true
    mainContainerView.addSubview(mainOverlayView)

    mainOverlayView.edgesToSuperview()

    view = stackView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    updateMinMainContainerViewSize()
  }

  override func viewDidLayout() {
    super.viewDidLayout()

    if let window = view.window {
      let titleBarHeight = window.contentView!.frame.height - window.contentLayoutRect.height
      tablineView.preferredViewHeight = titleBarHeight
    }
  }

  func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isFontUpdated {
      updateMinMainContainerViewSize()
      reportOuterGridSizeChangedIfNeeded()
    }

    tablineView.render(stateUpdates)
    mainView.render(stateUpdates)
  }

  func showMainView(on: Bool) {
    mainOverlayView.isHidden = on
  }

  func reportOuterGridSizeChangedIfNeeded() {
    let outerGridSizeNeeded = IntegerSize(
      columnsCount: Int(mainContainerView.frame.width / store.font.cellWidth),
      rowsCount: Int(mainContainerView.frame.height / store.font.cellHeight)
    )
    if 
      let outerGrid = store.outerGrid,
      outerGrid.cells.size != outerGridSizeNeeded,
      outerGridSizeNeeded != reportedOuterGridSize
    {
      reportedOuterGridSize = outerGridSizeNeeded

      Task {
        await store.instance.report(gridWithID: Grid.OuterID, changedSizeTo: outerGridSizeNeeded)
      }
    }
  }

  func point(forGridID gridID: Grid.ID, gridPoint: IntegerPoint) -> CGPoint? {
    mainView.point(forGridID: gridID, gridPoint: gridPoint)
  }

  func estimatedContentSize(outerGridSize: IntegerSize) -> CGSize {
    let mainFrameSize = outerGridSize * store.font.cellSize
    return .init(
      width: mainFrameSize.width,
      height: mainFrameSize.height + tablineView.intrinsicContentSize.height
    )
  }

  private let store: Store
  private let minOuterGridSize: IntegerSize
  private let tablineView: TablineView
  private let mainContainerView = NSView()
  private var mainContainerViewConstraints: (width: NSLayoutConstraint, height: NSLayoutConstraint)?
  private let mainView: MainView
  private let mainOverlayView = NSVisualEffectView()
  private var reportedOuterGridSize: IntegerSize?
  private var preMaximizeWindowFrame: CGRect?

  private func updateMinMainContainerViewSize() {
    let size = minOuterGridSize * store.font.cellSize
    mainContainerViewConstraints!.width.constant = size.width
    mainContainerViewConstraints!.height.constant = size.height
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
          animate: true
        )
      }

    } else {
      if let preMaximizeWindowFrame, window.frame != preMaximizeWindowFrame {
        window.setFrame(preMaximizeWindowFrame, display: true, animate: true)
      }
    }
  }
}
