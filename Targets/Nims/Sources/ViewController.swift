//
//  ViewController.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit

class ViewController: NSViewController {
  init() {
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    self.view = NSView(
      frame: .init(
        origin: .zero,
        size: .init(width: 1280, height: 960)
      )
    )
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    Store.shared.notifications
      .subscribe(onNext: { [weak self] in self?.handle(notifications: $0) })
      .disposed(by: self.associatedDisposeBag)
  }

  private var gridViews = [Int: GridView]()

  private func handle(notifications: [Store.Notification]) {
    for notification in notifications {
      switch notification {
      case let .gridCreated(id):
        let gridView = GridView(id: id)
        gridView.frame = self.view.bounds
          .offsetBy(dx: 200, dy: 200)
        self.view.addSubview(gridView)
        self.gridViews[id] = gridView
        self.showCurrentGrid()

      case let .gridDestroyed(id):
        guard let gridView = gridViews[id] else {
          assertionFailure()
          continue
        }
        gridView.removeFromSuperview()
        self.gridViews.removeValue(forKey: id)
        self.showCurrentGrid()

      case .currentGridChanged:
        self.showCurrentGrid()

      default:
        break
      }
    }
  }

  private func showCurrentGrid() {
    self.gridViews
      .forEach { id, gridView in
        gridView.isHidden = Store.shared.state.currentGridID != id
      }
  }
}
