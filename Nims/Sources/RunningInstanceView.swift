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
  private var nimsFont: NimsFont

  public var body: some View {
    WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: {
        $0.outerGridSize == $1.outerGridSize
      },
      content: { state in
        VStack(spacing: 0) {
          HeaderView(store: store)
            .frame(idealHeight: 44, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)

          if let outerGridSize = state.outerGridSize {
            GridsView(store: store, reportMouseEvent: reportMouseEvent)
              .frame(size: outerGridSize * nimsFont.cellSize, alignment: .topLeading)
              .fixedSize()
          }
        }
//        .overlay {
//          let cmdlinesStore = store
//            .scope(state: CmdlinesView.Model.init(model:))
//
//          WithViewStore(
//            cmdlinesStore,
//            observe: { $0 },
//            removeDuplicates: {
//              $0.cmdlineUpdateFlag == $1.cmdlineUpdateFlag
//            },
//            content: { viewStore in
//              if !viewStore.instanceState.cmdlines.isEmpty {
//                CmdlinesView(store: cmdlinesStore)
//              }
//            }
//          )
//        }
      }
    )
  }
}
