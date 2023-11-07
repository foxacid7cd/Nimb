// SPDX-License-Identifier: MIT

import AppKit
import Library

public class MainViewController: NSViewController {
  init(store: Store, minOuterGridSize: IntegerSize) {
    self.store = store
    self.minOuterGridSize = minOuterGridSize
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func windowFrame(forGridID gridID: Grid.ID, gridFrame: IntegerRectangle) -> CGRect? {
    mainView.windowFrame(forGridID: gridID, gridFrame: gridFrame)
  }

  override public func loadView() {
    stackView.spacing = 0
    stackView.orientation = .vertical
    customView.addSubview(stackView)
    stackView.edgesToSuperview()

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

    view = customView
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    updateMinMainContainerViewSize()
  }

  override public func viewDidLayout() {
    super.viewDidLayout()

    if let window = view.window {
      let titleBarHeight = window.contentView!.frame.height - window.contentLayoutRect.height
      tablineView.preferredViewHeight = titleBarHeight
    }
  }

  public func render(_ stateUpdates: State.Updates) {
    tablineView.render(stateUpdates)
    mainView.render(stateUpdates)

    if stateUpdates.isFontUpdated {
      updateMinMainContainerViewSize()
      reportOuterGridSizeChanged()
    }

    if stateUpdates.isMouseUserInteractionEnabledUpdated {
      customView.isUserInteractionEnabled = store.state.isMouseUserInteractionEnabled
    }

    view.layoutSubtreeIfNeeded()
  }

  public func reportOuterGridSizeChanged() {
    let outerGridSizeNeeded = IntegerSize(
      columnsCount: Int(mainContainerView.frame.width / store.font.cellWidth),
      rowsCount: Int(mainContainerView.frame.height / store.font.cellHeight)
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

  private let store: Store
  private lazy var customView = CustomView()
  private lazy var stackView = NSStackView(views: [])
  private let minOuterGridSize: IntegerSize
  private lazy var tablineView = TablineView(store: store)
  private let mainContainerView = NSView()
  private var mainContainerViewConstraints: (width: NSLayoutConstraint, height: NSLayoutConstraint)?
  private lazy var mainView = MainView(store: store)
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
