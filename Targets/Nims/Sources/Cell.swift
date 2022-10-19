//
//  Cell.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 19.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Library

struct Cell: Hashable {
  var text: String
  var hlID: Int
}

typealias CellGrid = Library.Grid<Cell?>
