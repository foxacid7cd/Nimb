// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim

class MainViewController: NSViewController {
  private let store: Store
  private var task: Task<Void, Never>?
  private let font = NimsFont()

  init(store: Store) {
    self.store = store
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
    let view = NSView()

    let mainView = MainView(store: store)
    mainView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(mainView)
    view.addConstraints([
      mainView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      mainView.topAnchor.constraint(equalTo: view.topAnchor),
      mainView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      mainView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])

    self.view = view
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
      preferredContentSize = outerGridSize * font.cellSize

    } else {
      preferredContentSize = .init()
    }
  }
}