// SPDX-License-Identifier: MIT

import CasePaths
import Collections
import ComposableArchitecture
import IdentifiedCollections
import Library
import Neovim
import Overture
import SwiftUI
import Tagged

public struct RunningInstanceView: View {
  public init(
    store: StoreOf<RunningInstanceReducer>,
    instance: Instance,
    reportMouseEvent: @escaping (MouseEvent) -> Void
  ) {
    self.store = store
    self.instance = instance
    self.reportMouseEvent = reportMouseEvent
  }

  private var store: StoreOf<RunningInstanceReducer>
  private var instance: Instance
  private var reportMouseEvent: (MouseEvent) -> Void

  @Environment(\.nimsFont)
  private var font: NimsFont

  public var body: some View {
    VStack(spacing: 0) {
      HeaderView(store: store, instance: instance)
        .frame(idealHeight: 44, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)

      if let outerGridSize = instance.state.grids[.outer]?.cells.size {
        GridsView(store: store, instance: instance, reportMouseEvent: reportMouseEvent)
          .frame(size: outerGridSize * font.cellSize, alignment: .topLeading)
          .fixedSize()
      }
    }
  }
}
