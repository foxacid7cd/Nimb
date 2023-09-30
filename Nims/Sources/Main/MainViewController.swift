// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim

final class MainViewController: NSViewController {
  init(store: Store, initialOuterGridSize: IntegerSize) {
    self.store = store
    self.initialOuterGridSize = initialOuterGridSize
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

    mainContainerView.clipsToBounds = true
    stackView.addArrangedSubview(mainContainerView)

    mainContainerView.addSubview(mainView)

    mainView.centerXToSuperview()
    mainView.topToSuperview()

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

  func render(_ stateUpdates: State.Updates) {
    if stateUpdates.isOuterGridLayoutUpdated || stateUpdates.isFontUpdated {
      updateMinMainContainerViewSize()
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

  private let store: Store
  private let initialOuterGridSize: IntegerSize
  private let tablineView: TablineView
  private let mainContainerView = NSView()
  private var mainContainerViewConstraints: (width: NSLayoutConstraint, height: NSLayoutConstraint)?
  private let mainView: MainView
  private let mainOverlayView = NSVisualEffectView()
  private var reportedOuterGridSize: IntegerSize?

  private func updateMinMainContainerViewSize() {
    let outerGridSize = store.outerGrid?.cells.size ?? initialOuterGridSize
    let size = outerGridSize * store.font.cellSize
    mainContainerViewConstraints!.width.constant = size.width
    mainContainerViewConstraints!.height.constant = size.height
  }
}
