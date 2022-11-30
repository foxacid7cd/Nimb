//
//  Grid.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 30.11.2022.
//

import AsyncAlgorithms
import Cocoa

actor Grid {
  init(appearance: Appearance) {
    self.appearance = appearance
  }

  actor Line {
    init() {}

    func resize(to length: Int) {
      self.cells = (0 ..< length)
        .map { _ in
          Cell()
        }
    }

    private var cells = [Cell]()
  }

  actor Cell {
    var text = " "
    var highlightID: Int?
  }

  func resize(to size: GridSize) async {
    var lines = [Line]()

    for _ in 0 ..< size.height {
      let line = Line()
      await line.resize(to: size.width)

      lines.append(line)
    }

    self.lines = lines
  }

  private let appearance: Appearance
  private var lines = [Line]()
}
