// SPDX-License-Identifier: MIT

import AppKit
import Library
import Neovim

class MainViewController: NSViewController {
  private let instance: Instance
  private var task: Task<Void, Never>?
  private let font = NimsFont()

  init(instance: Instance) {
    self.instance = instance
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
    view.translatesAutoresizingMaskIntoConstraints = false
    view.wantsLayer = true
    view.layer!.backgroundColor = .black
    self.view = view
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    updatePreferredContentSize()

    task = Task {
      for await stateUpdates in instance.stateUpdatesStream() {
        if stateUpdates.updatedLayoutGridIDs.contains(.outer) {
          updatePreferredContentSize()
        }
      }
    }
  }

  private func updatePreferredContentSize() {
    if let outerGridSize = instance.state.grids[.outer]?.cells.size {
      preferredContentSize = outerGridSize * font.cellSize

    } else {
      preferredContentSize = .init()
    }
  }
}
