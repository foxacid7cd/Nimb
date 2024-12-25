// SPDX-License-Identifier: MIT

import AppKit

@PublicInit
public struct GlyphRun: @unchecked Sendable {
  public var appKitFont: NSFont
  public var textMatrix: CGAffineTransform
  public var glyphs: [CGGlyph]
  public var positions: [CGPoint]
  public var advances: [CGSize]
}
