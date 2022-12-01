//
//  NSColor+RGB.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 29.11.2022.
//

import Cocoa

extension NSColor {
  convenience init(rgb: Int, alpha: Double = 1) {
    self.init(
      red: Double((rgb & 0xFF0000) >> 16) / 255.0,
      green: Double((rgb & 0xFF00) >> 8) / 255.0,
      blue: Double(rgb & 0xFF) / 255.0,
      alpha: alpha
    )
  }
}
