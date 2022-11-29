//
//  NimsUI.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Cocoa

class NimsUI {
  private let nimsAppearance: NimsAppearance
  private let mainWindow: MainWindow
  
  @MainActor
  init() {
    let nimsAppearance = NimsAppearance(regularFont: .monospacedSystemFont(ofSize: 12, weight: .medium))
    self.nimsAppearance = nimsAppearance
    
    let mainWindow = MainWindow(nimsAppearance: nimsAppearance)
    self.mainWindow = mainWindow
  }
  
  @MainActor
  func start() {
    mainWindow.becomeMain()
    mainWindow.makeKeyAndOrderFront(nil)
  }
  
  @MainActor
  func gridResize(gridID: Int, gridSize: GridSize) {
    self.mainWindow.gridResize(gridID: gridID, gridSize: gridSize)
  }
  
  @MainActor
  func gridLine(gridID: Int, origin: GridPoint, cells: [Cell]) {
    self.mainWindow.gridLine(gridID: gridID, origin: origin, cells: cells)
  }
  
  @MainActor
  func winPos(gridID: Int, winRef: WinRef, winFrame: GridRectangle) {
    self.mainWindow.winPos(gridID: gridID, winRef: winRef, winFrame: winFrame)
  }
}
