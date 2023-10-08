// SPDX-License-Identifier: MIT

import AppKit

extension NSColor {
  convenience init(hueSource: String, saturation: Double = 1, brightness: Double = 1, alpha: Double = 1) {
    let rgb = hueSource.sdbmHash
      .remainderReportingOverflow(dividingBy: 0xFFFFFF)
      .partialValue

    var hue: CGFloat = 0
    NimsColor(rgb: rgb)
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

private extension String {
  var sdbmHash: Int {
    let unicodeScalars = unicodeScalars.map(\.value)
    return unicodeScalars.reduce(0) {
      (Int($1) &+ ($0 << 6) &+ ($0 << 16)).addingReportingOverflow(-$0).partialValue
    }
  }
}
