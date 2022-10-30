//
//  Event.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 24.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Library

enum Event: Hashable {
  case windowGridRowChanged(gridID: Int, origin: GridPoint, columnsCount: Int)
  case windowGridRectangleChanged(gridID: Int, rectangle: GridRectangle)
  case windowGridRectangleMoved(gridID: Int, rectangle: GridRectangle, toOrigin: GridPoint)
  case windowGridCleared(gridID: Int)

  case windowFrameChanged(gridID: Int)
  case windowHid(gridID: Int)
  case windowClosed(gridID: Int)

  case cursorMoved(previousCursor: State.Cursor?)
  case fontChanged
  case highlightChanged
  case flushRequested
}
