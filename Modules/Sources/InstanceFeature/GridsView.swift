// SPDX-License-Identifier: MIT

import Combine
import ComposableArchitecture
import IdentifiedCollections
import Library
import Neovim
import Overture
import SwiftUI

public struct GridsView: NSViewRepresentable {
  public init(store: Store<InstanceView.State, InstanceView.Action>) {
    self.store = store
  }

  private var store: Store<InstanceView.State, InstanceView.Action>

  @Environment(\.nimsAppearance)
  private var nimsAppearance: NimsAppearance

  public func makeNSView(context: Context) -> NSView {
    let view = NSView()
    view.bind(
      nimsAppearance: nimsAppearance,
      store: store
    )

    return view
  }

  public func updateNSView(_ nsView: NSView, context: Context) {
    nsView.bind(
      nimsAppearance: nimsAppearance,
      store: store
    )
  }

  public final class NSView: AppKit.NSView {
    private var stateCancellable: AnyCancellable?

    private var nimsAppearance: NimsAppearance!
    private var store: Store<InstanceView.State, InstanceView.Action>!

    private var state: ViewStore<InstanceView.State, InstanceView.Action>!

    public func bind(
      nimsAppearance: NimsAppearance,
      store: Store<InstanceView.State, InstanceView.Action>
    ) {
      stateCancellable?.cancel()

      self.nimsAppearance = nimsAppearance
      self.store = store

      state = ViewStore(
        store,
        observe: { $0 },
        removeDuplicates: {
          $0.gridsUpdateFlag == $1.gridsUpdateFlag
        }
      )

      stateCancellable = state.publisher
        .sink { [weak self] _ in
          self?.render()
        }
    }

    private var gridViews = IntKeyedDictionary<GridView.NSView>()

    private func render() {
//      let outerGridView = gridViews[Grid.ID.outer] ?? {
//        let view = GridView.NSView()
//        self.addSubview(view)
//        gridViews[Grid.ID.outer.rawValue] = view
//
//        return view
//      }()
    }

    override public func layout() {}
  }

  //  public var body: some View {
//    WithViewStore(
//      store,
//      observe: { $0 },
//      removeDuplicates: {
//        $0.gridsLayoutUpdateFlag == $1.gridsLayoutUpdateFlag
//      },
//      content: { _ in
//        GeometryReader { _ in
//          let frame = geometryProxy.frame(in: .local)
//
//          GridView(
//            store: store
//              .scope(
//                state: { model in
//                  makeGridViewModel(
//                    gridID: .outer,
//                    model: model
//                  )
//                },
//                action: Action.gridView(action:)
//              ),
//            reportMouseEvent: viewStore.reportMouseEvent
//          )
//          .frame(size: frame.size, alignment: .topLeading)
//          .fixedSize()
//          .offset(frame.origin)
//          .zIndex(0)
//          .coordinateSpace(name: Grid.ID.outer)
//
//          ForEach(viewStore.windows) { window in
//            let frame = window.frame * nimsAppearance.cellSize
//
//            GridView(
//              store: store
//                .scope(
//                  state: { model in
//                    makeGridViewModel(
//                      gridID: window.gridID,
//                      model: model
//                    )
//                  },
//                  action: Action.gridView(action:)
//                ),
//              reportMouseEvent: viewStore.reportMouseEvent
//            )
//            .frame(size: frame.size, alignment: .topLeading)
//            .fixedSize()
//            .offset(frame.origin)
//            .zIndex(Double(window.zIndex) / 1000 + 1000)
//            .opacity(window.isHidden ? 0 : 1)
//            .coordinateSpace(name: window.gridID)
//          }

//          ForEachStore(
//            store.scope(state: \.floatingWindows, action: GridsView.Action.floatingWindow(id:action:)),
//            content: { store in
//              WithViewStore(
//                store,
//                observe: { $0 },
//                removeDuplicates: { $0.updateFlag == $1.updateFlag },
//                content: { floatingWindow in
//                  Text("\(floatingWindow.reference)")
  //                  let anchorGridFrame = geometryProxy.frame(
//                    in: .named(floatingWindow.anchorGridID)
//                  )
//                  let originOffset = CGPoint(
//                    x: floatingWindow.anchorColumn * nimsAppearance.cellWidth,
//                    y: floatingWindow.anchorRow * nimsAppearance.cellHeight
//                  )
//                  let grid = viewStore.grids[floatingWindow.gridID]!
//                  let size = grid.cells.size * nimsAppearance.cellSize
//
//                  let frame = CGRect(
//                    origin: anchorGridFrame.origin + originOffset,
//                    size: size
//                  )

//                  GridView(
//                    store: self.store
//                      .scope(
//                        state: { model in
//                          makeGridViewModel(
//                            gridID: floatingWindow.gridID,
//                            model: model
//                          )
//                        },
//                        action: Action.gridView(action:)
//                      ),
//                    reportMouseEvent: viewStore.reportMouseEvent
//                  )
//                  .frame(size: frame.size, alignment: .topLeading)
//                  .fixedSize()
//                  .offset(frame.origin)
//                  .zIndex(Double(floatingWindow.zIndex) / 1000 + 1_000_000)
//                  .opacity(floatingWindow.isHidden ? 0 : 1)
//                  .coordinateSpace(name: floatingWindow.gridID)
//                })
//            }
//          )
//        }
//      }
//    )
//  }
//
//  @Environment(\.nimsAppearance)
//  private var nimsAppearance: NimsAppearance

//  private func makeGridViewModel(gridID: Grid.ID, model: Model) -> GridView.Model {
//    .init(
//      gridID: gridID,
//      grids: model.grids,
//      cursor: model.cursor,
//      modeInfo: model.modeInfo,
//      mode: model.mode,
//      cursorBlinkingPhase: model.cursorBlinkingPhase
//
//  }
}
