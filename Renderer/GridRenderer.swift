// SPDX-License-Identifier: MIT

import IOSurface

final class GridRenderer {
  private let surface: IOSurface
  private let scale: CGFloat
  private let gridID: Int

  init(surface: IOSurface, scale: CGFloat, gridID: Int) {
    self.surface = surface
    self.scale = scale
    self.gridID = gridID
  }
}
