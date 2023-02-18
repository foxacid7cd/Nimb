// SPDX-License-Identifier: MIT

import ComposableArchitecture
import IdentifiedCollections
import Library

public struct InstanceViewModel: Equatable {
  public init(
    font: Font,
    defaultForegroundColor: Color,
    defaultBackgroundColor: Color,
    defaultSpecialColor: Color,
    outerGridSize: IntegerSize,
    highlights: IdentifiedArrayOf<Highlight>,
    title: String,
    modeInfo: ModeInfo,
    instanceUpdateFlag: Bool
  ) {
    self.font = font
    self.defaultForegroundColor = defaultForegroundColor
    self.defaultBackgroundColor = defaultBackgroundColor
    self.defaultSpecialColor = defaultSpecialColor
    self.outerGridSize = outerGridSize
    self.highlights = highlights
    self.title = title
    self.instanceUpdateFlag = instanceUpdateFlag
    self.modeInfo = modeInfo
    self.instanceUpdateFlag = instanceUpdateFlag
  }

  public init?(instance: Instance.State) {
    guard
      let font = instance.font ?? instance.defaultFont,
      let defaultHighlight = instance.highlights[id: .default],
      let defaultForegroundColor = defaultHighlight.foregroundColor,
      let defaultBackgroundColor = defaultHighlight.backgroundColor,
      let defaultSpecialColor = defaultHighlight.specialColor,
      let outerGrid = instance.outerGrid,
      let title = instance.title,
      let modeInfo = instance.modeInfo
    else {
      return nil
    }

    self.init(
      font: font,
      defaultForegroundColor: defaultForegroundColor,
      defaultBackgroundColor: defaultBackgroundColor,
      defaultSpecialColor: defaultSpecialColor,
      outerGridSize: outerGrid.cells.size,
      highlights: instance.highlights,
      title: title,
      modeInfo: modeInfo,
      instanceUpdateFlag: instance.instanceUpdateFlag
    )
  }

  public var font: Font
  public var defaultForegroundColor: Color
  public var defaultBackgroundColor: Color
  public var defaultSpecialColor: Color
  public var highlights: IdentifiedArrayOf<Highlight>
  public var outerGridSize: IntegerSize
  public var title: String
  public var modeInfo: ModeInfo
  public var instanceUpdateFlag: Bool
}
