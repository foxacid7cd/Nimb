// Copyright © 2022 foxacid7cd. All rights reserved.

import IdentifiedCollections
import SwiftUI

struct ViewModel {
  struct Grid: Identifiable {
    let id: Int
    let index: Int
    var frame: CGRect
    var rowAttributedStrings: [AttributedString]
  }

  var outerSize = CGSize()
  var grids = [Grid]()
  var rowHeight: Double = 0
  var cursor: (gridID: Int, rect: CGRect)?
}

enum ViewModelEffect {
  case initial
  case canvasChanged
}
