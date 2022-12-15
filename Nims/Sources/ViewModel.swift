// Copyright © 2022 foxacid7cd. All rights reserved.

import IdentifiedCollections
import SwiftUI

struct ViewModel {
  struct Grid: Identifiable {
    let id: Int
    var frame: CGRect
    var rows: [State.Row]
  }

  var outerSize: CGSize
  var grids: [Grid]
  var rowHeight: Double
  var defaultBackgroundColor: Color
}

enum ViewModelEffect {
  case initial
  case outerSizeChanged
  case canvasChanged
}
