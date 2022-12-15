// Copyright © 2022 foxacid7cd. All rights reserved.

import IdentifiedCollections
import SwiftUI

struct ViewModel {
  struct Grid: Identifiable {
    let id: Int
    var frame: CGRect
    var rows: [Row]
  }

  struct Row: Identifiable {
    let id: Int
    var attributedString: AttributedString
  }

  var outerSize: CGSize
  var grids: IdentifiedArrayOf<Grid>
  var rowHeight: Double
  var defaultBackgroundColor: Color
}
