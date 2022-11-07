//
//  GridEvent.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 24.10.2022.
//  Copyright © 2022 foxacid7cd. All rights reserved.
//

import Library

enum Event: Hashable {
  case grid(id: Int, model: GridEvent)
  case cursor(previousCusor: State.Cursor?)
  case flushRequested
  case appearanceChanged
}

enum GridEvent: Hashable {
  case windowGridRowChanged(origin: GridPoint, columnsCount: Int)
  case windowGridRectangleChanged(rectangle: GridRectangle)
  case windowGridRectangleMoved(rectangle: GridRectangle, toOrigin: GridPoint)
  case windowGridCleared
  case windowFrameChanged
  case windowHid
  case windowClosed
}
