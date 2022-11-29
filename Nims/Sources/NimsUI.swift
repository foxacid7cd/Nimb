//
//  NimsUI.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Cocoa
import MessagePack

class NimsUI {
  private let nimsAppearance: NimsAppearance
  private let mainWindow: MainWindow

  @MainActor
  init() {
    let font = NSFont(name: "BlexMono Nerd Font", size: 12)!

    let nimsAppearance = NimsAppearance(
      regularFont: font
    )
    self.nimsAppearance = nimsAppearance

    let mainWindow = MainWindow(nimsAppearance: nimsAppearance)
    self.mainWindow = mainWindow
  }

  @MainActor
  func start() {
    self.mainWindow.becomeMain()
    self.mainWindow.makeKeyAndOrderFront(nil)
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

  @MainActor
  func defaultColorsSet(rgbFg: Int, rgbBg: Int, rgbSp: Int) {
    self.nimsAppearance.defaultColorsSet(rgbFg: rgbFg, rgbBg: rgbBg, rgbSp: rgbSp)
  }

  @MainActor
  func hlAttrDefine(id: Int, rgbAttr: [(key: String, value: MessageValue)]) {
    self.nimsAppearance.hlAttrDefine(id: id, rgbAttr: rgbAttr)
  }
}
