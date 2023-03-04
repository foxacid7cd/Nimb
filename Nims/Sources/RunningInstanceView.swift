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
  public init(store: StoreOf<RunningInstanceReducer>, reportMouseEvent: @escaping (MouseEvent) -> Void) {
    self.store = store
    self.reportMouseEvent = reportMouseEvent
  }

  private var store: StoreOf<RunningInstanceReducer>
  private var reportMouseEvent: (MouseEvent) -> Void

  @Environment(\.nimsFont)
  private var font: NimsFont

  public var body: some View {
    WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: { lhs, rhs in
        guard
          lhs.cmdlinesUpdateFlag == rhs.cmdlinesUpdateFlag,
          lhs.msgShowsUpdateFlag == rhs.msgShowsUpdateFlag
        else {
          return true
        }

        return false
      },
      content: { state in
        let mainView = WithViewStore(
          store,
          observe: { $0 },
          removeDuplicates: {
            $0.outerGridSizeUpdateFlag == $1.outerGridSizeUpdateFlag
          },
          content: { state in
            VStack(spacing: 0) {
              HeaderView(store: store)
                .frame(idealHeight: 44, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)

              if let outerGridSize = state.outerGridSize {
                GridsView(store: store, reportMouseEvent: reportMouseEvent)
                  .frame(size: outerGridSize * font.cellSize, alignment: .topLeading)
                  .fixedSize()
              }
            }
          }
        )

        if
          state.cmdlines.isEmpty,
          state.msgShows.isEmpty
        {
          mainView

        } else {
          mainView
            .overlay { OverlayView(store: store) }
        }
      }
    )
  }
}
