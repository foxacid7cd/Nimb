//
//  MainWindow.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Cocoa

class MainWindow: NSWindow {
  private let nimsAppearance: NimsAppearance
  private let mainView: MainView
  private var outerGridSize = GridSize()
  
  init(nimsAppearance: NimsAppearance) {
    self.nimsAppearance = nimsAppearance
    
    let mainView = MainView(nimsAppearance: nimsAppearance)
    self.mainView = mainView
    
    super.init(
      contentRect: .zero,
      styleMask: [.titled, .miniaturizable, .closable],
      backing: .buffered,
      defer: true
    )
    
    self.contentView = mainView
  }
  
  override var canBecomeMain: Bool {
    true
  }
  
  override var canBecomeKey: Bool {
    true
  }
  
  func gridResize(gridID: Int, gridSize: GridSize) {
    if gridID == 1 {
      self.outerGridSize = gridSize
      self.updateContentSize()
    }
    
    self.mainView.gridResize(gridID: gridID, gridSize: gridSize)
  }
  
  func gridLine(gridID: Int, origin: GridPoint, cells: [Cell]) {
    self.mainView.gridLine(gridID: gridID, origin: origin, cells: cells)
  }
  
  func winPos(gridID: Int, winRef: WinRef, winFrame: GridRectangle) {
    self.mainView.winPos(gridID: gridID, winRef: winRef, winFrame: winFrame)
  }
  
  private func updateContentSize() {
    self.setContentSize(self.outerGridSize * self.nimsAppearance.cellSize)
  }
}
