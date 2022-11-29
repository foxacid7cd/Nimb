//
//  MainView.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Cocoa
import Collections
import OSLog

class MainView: NSView {
  private var nimsAppearance: NimsAppearance
  private var gridViews = PersistentDictionary<Int, GridView>()
  private var outerGridSize = GridSize()
  
  init(nimsAppearance: NimsAppearance) {
    self.nimsAppearance = nimsAppearance
    
    super.init(frame: .zero)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func gridResize(gridID: Int, gridSize: GridSize) {
    if gridID == 1 {
      self.outerGridSize = gridSize
      
      for gridView in self.gridViews.values {
        gridView.outerGridSize = gridSize
        
        gridView.updateViewFrame()
      }
    }
    
    let gridView = self.gridView(gridID: gridID)
    
    gridView.gridSize = gridSize
    gridView.updateViewFrame()
    
    if gridView.superview == nil {
      self.addSubview(gridView)
    }
  }
  
  func gridLine(gridID: Int, origin: GridPoint, cells: [Cell]) {
    guard let gridView = self.gridViews[gridID] else {
      return
    }
    
    gridView.gridLine(origin: origin, cells: cells)
  }
  
  func winPos(gridID: Int, winRef: WinRef, winFrame: GridRectangle) {
    let gridView = self.gridView(gridID: gridID)
    
    gridView.winRef = winRef
    gridView.winFrame = winFrame
    gridView.updateViewFrame()
    
    self.addSubview(gridView)
  }
  
  private func gridView(gridID: Int) -> GridView {
    if let gridView = self.gridViews[gridID] {
      return gridView
      
    } else {
      let gridView = GridView(nimsAppearance: self.nimsAppearance)
      self.gridViews[gridID] = gridView
      
      gridView.outerGridSize = self.outerGridSize
      return gridView
    }
  }
}

private class GridView: NSView {
  var gridSize = GridSize()
  var winRef: WinRef?
  var winFrame: GridRectangle?
  var outerGridSize = GridSize()
  
  private var nimsAppearance: NimsAppearance
  private var drawRuns = [(CGRect, DrawRun)]()
  
  init(nimsAppearance: NimsAppearance) {
    self.nimsAppearance = nimsAppearance
    
    super.init(frame: .zero)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func draw(_ dirtyRect: NSRect) {
    let context = NSGraphicsContext.current!
    
    context.saveGraphicsState()
    defer { context.restoreGraphicsState() }
    
    for (index, arg) in drawRuns.enumerated().reversed() {
      let (rect, drawRun) = arg
      
      guard dirtyRect.contains(rect) else {
        continue
      }
      drawRuns.remove(at: index)
      
      context.cgContext.setShouldAntialias(false)
      context.cgContext.setFillColor(gray: self.winRef != nil ? 0 : 0.25, alpha: 1)
      context.cgContext.fill([rect])
      
      context.cgContext.setShouldAntialias(true)
      context.cgContext.setFillColor(gray: 1, alpha: 1)
      
      let glyphRun = drawRun.glyphRun
      CTFontDrawGlyphs(
        glyphRun.font,
        glyphRun.glyphs,
        glyphRun.positionsWithOffset(
          dx: rect.origin.x,
          dy: rect.origin.y + self.nimsAppearance.cellSize.height - glyphRun.font.ascender
        ),
        glyphRun.glyphs.count,
        context.cgContext
      )
    }
  }
  
  func gridLine(origin: GridPoint, cells: [Cell]) {
    let cellSize = self.nimsAppearance.cellSize
    
    let origin = GridPoint(
      x: origin.x,
      y: self.gridSize.height - origin.y - 1
    )
    
    let gridRectangle = GridRectangle(
      origin: origin,
      size: .init(
        width: cells.count,
        height: 1
      )
    )
    let rect = gridRectangle * cellSize
    
    let drawRun = DrawRun.make(
      origin: origin,
      characters: cells.compactMap { $0.character },
      font: nimsAppearance.regularFont
    )
    
    self.drawRuns.append((rect, drawRun))
    self.setNeedsDisplay(rect)
  }

  func updateViewFrame() {
    self.frame = self.gridFrame * self.nimsAppearance.cellSize
  }
  
  var gridFrame: GridRectangle {
    if let winFrame {
      return .init(
        origin: .init(
          x: winFrame.origin.x,
          y: self.outerGridSize.height - winFrame.origin.y - winFrame.size.height
        ),
        size: winFrame.size
      )
    }
    
    return .init(size: self.gridSize)
  }
}
