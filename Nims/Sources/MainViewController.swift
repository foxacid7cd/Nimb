// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim

final class MainViewController: NSViewController {
  private let store: Store
  private let tablineView: TablineView
  private let mainView: MainView
  private var task: Task<Void, Never>?
  private let font = NimsFont()

  init(store: Store) {
    self.store = store
    tablineView = .init(store: store)
    mainView = .init(store: store)
    super.init(nibName: nil, bundle: nil)
  }

  deinit {
    task?.cancel()
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

    stackView.addArrangedSubview(mainView)

    view = stackView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    updatePreferredContentSize()

    task = Task {
      for await stateUpdates in store.stateUpdatesStream() {
        guard !Task.isCancelled else {
          return
        }

        if stateUpdates.updatedLayoutGridIDs.contains(.outer) {
          updatePreferredContentSize()
        }
      }
    }
  }

  private func updatePreferredContentSize() {
    if let outerGridSize = store.grids[.outer]?.cells.size {
      let mainViewSize = outerGridSize * font.cellSize
      let tablineHeight = tablineView.intrinsicContentSize.height

      preferredContentSize = .init(
        width: mainViewSize.width,
        height: mainViewSize.height + tablineHeight
      )

    } else {
      preferredContentSize = .init()
    }
  }

  public func point(forGridID gridID: Grid.ID, gridPoint: IntegerPoint) -> CGPoint? {
    mainView.point(forGridID: gridID, gridPoint: gridPoint)
  }
}
