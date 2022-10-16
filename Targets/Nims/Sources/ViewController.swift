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
    let view = NSStackView()

    Task {
      for await array in store.notifications {
        for notification in array {
          switch notification {
          case let .gridCreated(id):
            let gridView = GridView(id: id, store: store)
            view.addArrangedSubview(gridView)
            gridViews[id] = gridView

          case let .gridDestroyed(id):
            guard let gridView = gridViews[id] else {
              "tried to destroy unexisting grid".fail().failAssertion()
              continue
            }
            gridView.removeFromSuperview()
            gridViews.removeValue(forKey: id)

          default:
            continue
          }
        }
      }
    }

    self.view = view
  }

  private var store: Store
  private var gridViews = [Int: GridView]()
}
