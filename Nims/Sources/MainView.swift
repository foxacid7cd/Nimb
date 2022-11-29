//
//  MainView.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Cocoa
import Collections

class MainView: NSView {
  private var nimsAppearance: NimsAppearance
  private var gridViews = PersistentDictionary<Int, GridView>()
  
  init(nimsAppearance: NimsAppearance) {
    self.nimsAppearance = nimsAppearance
    
    super.init(frame: .zero)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func gridResize(gridID: Int, gridSize: GridSize) {
    let gridView = self.gridView(gridID: gridID)
    
    gridView.gridSize = gridSize
    gridView.updateViewFrame()
    
    if gridView.superview == nil {
      self.addSubview(gridView)
    }
  }
  
  func winPos(gridID: Int, winRef: WinRef, winFrame: GridRectangle) {
    let gridView = self.gridView(gridID: gridID)
    
    gridView.winRef = winRef
    gridView.winFrame = winFrame
    
    self.addSubview(gridView)
  }
  
  private func gridView(gridID: Int) -> GridView {
    if let gridView = self.gridViews[gridID] {
      return gridView
      
    } else {
      let gridView = GridView(nimsAppearance: self.nimsAppearance)
      self.gridViews[gridID] = gridView
      return gridView
    }
  }
}

private class GridView: NSView {
  var gridSize = GridSize()
  var winRef: WinRef?
  var winFrame: GridRectangle?
  
  private var nimsAppearance: NimsAppearance
  
  init(nimsAppearance: NimsAppearance) {
    self.nimsAppearance = nimsAppearance
    
    super.init(frame: .zero)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func updateViewFrame() {
    if let winFrame = self.winFrame {
      self.frame = winFrame * self.nimsAppearance.cellSize
      
    } else {
      self.frame = .init(
        origin: .zero,
        size: self.gridSize * self.nimsAppearance.cellSize
      )
    }
  }
}
