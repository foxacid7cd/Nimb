//
//  ViewController.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Combine

class ViewController: NSViewController {
  init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    self.view = NSView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.store.notifications
      .sink { [weak self] in self?.handle(notifications: $0) }
      .store(in: &self.cancellables)
  }

  private var store: Store
  private var cancellables = Set<AnyCancellable>()
  private var gridViews = [Int: GridView]()

  private func handle(notifications: [Store.Notification]) {
    for notification in notifications {
      switch notification {
      case let .gridCreated(id):
        let gridView = GridView(store: store, id: id)
        gridView.frame = self.view.bounds
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
        continue
      }
    }
  }

  private func showCurrentGrid() {
    self.gridViews
      .forEach { id, gridView in
        gridView.isHidden = store.state.currentGridID != id
      }
  }
}
