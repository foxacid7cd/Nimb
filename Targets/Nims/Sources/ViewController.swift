//
//  ViewController.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 15.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import AppKit
import Combine
import Drawing

class ViewController: NSViewController {
  private let store: Store
  private lazy var drawingView = DrawingView()
  
  @MainActor
  init(store: Store) {
    self.store = store
    
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func loadView() {
    view = drawingView
  }
  
  func handle(updates: GridUpdates, forGridID id: Int) {
    print(id, updates)
  }
}
