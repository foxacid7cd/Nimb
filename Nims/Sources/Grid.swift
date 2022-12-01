//
//  Grid.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 01.12.2022.
//

import AsyncAlgorithms
import Cocoa

actor Grid {
  func resize(to size: Size) async {
    var rows = [Row]()

    for _ in 0 ..< size.height {
      let row = Row()
      await row.resize(to: size.width)

      rows.append(row)
    }

    self.rows = rows
  }

  private var rows = [Row]()
}

actor Row {
  func resize(to length: Int) {
    self.cells = (0 ..< length)
      .map { _ in
        Cell()
      }
  }

  private var cells = [Cell]()
}

actor Cell {
  init(text: String = " ", highlightID: Int? = nil) {
    self.text = text
    self.highlightID = highlightID
  }

  var text: String
  var highlightID: Int?
}
