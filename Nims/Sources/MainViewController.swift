// SPDX-License-Identifier: MIT

import AppKit

class MainViewController: NSViewController {
  init() {
    super.init(nibName: nil, bundle: nil)
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

    preferredContentSize = .init(width: 200, height: 200)
  }
}
