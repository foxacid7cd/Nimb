// SPDX-License-Identifier: MIT

import AppKit
import Neovim

extension NSColor {
  convenience init(hueSource: any Hashable, saturation: Double = 1, brightness: Double = 1, alpha: Double = 1) {
    let rgb = hueSource.hashValue
      .remainderReportingOverflow(dividingBy: 0xFFFFFF)
      .partialValue

    var hue: CGFloat = 0
    Color(rgb: rgb)
      .appKit
      .getHue(&hue, saturation: nil, brightness: nil, alpha: nil)

    self.init(
      colorSpace: .displayP3,
      hue: hue,
      saturation: saturation,
      brightness: brightness,
      alpha: alpha
    )
  }
}
