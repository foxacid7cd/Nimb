//
//  WindowController.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 17.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit

class WindowController: NSWindowController {
  init() {
    let viewController = ViewController()

    let window = NSWindow(
      contentRect: .init(),
      styleMask: [.titled],
      backing: .buffered,
      defer: true
    )
    window.contentViewController = viewController
    super.init(window: window)

    self.updateWindowTitle()

    Store.shared.notifications
      .subscribe(onNext: { [weak self] in self?.handle(notifications: $0) })
      .disposed(by: self.associatedDisposeBag)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func handle(notifications: [Store.Notification]) {
    for notification in notifications {
      switch notification {
      case .currentGridChanged:
        self.updateWindowTitle()

      default:
        continue
      }
    }
  }

  private func updateWindowTitle() {
    guard let window else { return }
    window.title = "Grid \(Store.state.currentGridID.logDescription)"
  }
}
