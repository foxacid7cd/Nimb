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

public struct InstanceView: View {
  public init(store: Store<State, Action>) {
    self.store = store
  }

  public var store: Store<State, Action>

  @dynamicMemberLookup
  public struct State {
    public init(instanceState: InstanceState, reportMouseEvent: @escaping (MouseEvent) -> Void, outerGrid: Grid) {
      self.instanceState = instanceState
      self.reportMouseEvent = reportMouseEvent
      self.outerGrid = outerGrid
    }

    public var instanceState: InstanceState
    public var reportMouseEvent: (MouseEvent) -> Void
    public var outerGrid: Grid

    public subscript<Value>(dynamicMember keyPath: KeyPath<InstanceState, Value>) -> Value {
      instanceState[keyPath: keyPath]
    }

    var headerViewModel: HeaderView.Model {
      .init(
        tabline: self.tabline,
        gridsLayoutUpdateFlag: self.gridsLayoutUpdateFlag
      )
    }

    var cmdlinesViewModel: CmdlinesView.Model {
      .init(
        cmdlines: self.cmdlines,
        cmdlineUpdateFlag: self.cmdlineUpdateFlag
      )
    }
  }

  public enum Action: Sendable {
    case headerView(action: HeaderView.Action)
  }

  public var body: some View {
    WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: {
        $0.instanceState.gridsLayoutUpdateFlag == $1.instanceState.gridsLayoutUpdateFlag
      },
      content: { state in
        VStack(spacing: 0) {
          HeaderView(
            store: store
              .scope(
                state: \.headerViewModel,
                action: Action.headerView(action:)
              )
          )
          .frame(idealHeight: 44, alignment: .topLeading)
          .fixedSize(horizontal: false, vertical: true)

          GridsView(store: store)
            .frame(size: state.outerGrid.cells.size * nimsAppearance.cellSize, alignment: .topLeading)
            .fixedSize()
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

  @Environment(\.nimsAppearance)
  private var nimsAppearance: NimsAppearance
}
