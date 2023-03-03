// SPDX-License-Identifier: MIT

import AppKit
import Combine
import ComposableArchitecture
import CustomDump
import IdentifiedCollections
import Library
import Neovim
import Overture
import SwiftUI

public struct GridsView: NSViewRepresentable {
  public init(store: StoreOf<RunningInstanceReducer>) {
    self.store = store
  }

  private var store: StoreOf<RunningInstanceReducer>

  @Environment(\.nimsFont)
  private var nimsFont: NimsFont

  public func makeNSView(context: Context) -> NSView {
    let view = NSView()
    view.bind(font: nimsFont, store: store)

    return view
  }

  public func updateNSView(_ nsView: NSView, context: Context) {}

  public final class NSView: AppKit.NSView {
    private var stateCancellable: AnyCancellable?
    private var font: NimsFont!
    private var store: StoreOf<RunningInstanceReducer>!
    private var viewStore: ViewStoreOf<RunningInstanceReducer>!

    private var state: Neovim.State {
      viewStore.state.stateContainer.state
    }

    public func bind(font: NimsFont, store: StoreOf<RunningInstanceReducer>) {
      stateCancellable?.cancel()

      self.font = font
      self.store = store

      viewStore = ViewStore(
        store,
        observe: { $0 },
        removeDuplicates: { _, _ in true }
      )

      stateCancellable = viewStore.publisher
        .sink { [weak self] state in
          state.stateContainer.observe { updates in
            self?.render(updates: updates)
          }

          self?.render(updates: nil)
        }
    }

    private var gridViews = IntKeyedDictionary<GridView>()

    private func render(updates: Neovim.State.Updates?) {
      guard let outerGridIntegerSize = state.grids[.outer]?.cells.size else {
        return
      }
      let outerGridSize = outerGridIntegerSize * font.cellSize

      let upsideDownTransform = CGAffineTransform(scaleX: 1, y: -1)
        .translatedBy(x: 0, y: -outerGridSize.height)

      let updatedLayoutGridIDs: Set<Neovim.Grid.ID>
      if let updates {
        updatedLayoutGridIDs = updates.updatedLayoutGridIDs

      } else {
        updatedLayoutGridIDs = .init(
          state.grids.keys
            .map(Grid.ID.init(_:))
        )
      }

      for gridID in updatedLayoutGridIDs {
        if let grid = state.grids[gridID] {
          let gridView = gridViews[gridID] ?? {
            let new = GridView()
            new.font = self.font
            new.stateContainer = self.viewStore.stateContainer
            new.gridID = gridID
            self.addSubview(new)

            self.sortSubviews(
              { firstView, secondView, _ in
                let firstOrdinal = (firstView as! GridView).ordinal
                let secondOrdinal = (secondView as! GridView).ordinal
                if firstOrdinal == secondOrdinal {
                  return .orderedSame

                } else if firstOrdinal < secondOrdinal {
                  return .orderedAscending

                } else {
                  return .orderedDescending
                }
              },
              context: nil
            )

            gridViews[gridID] = new
            return new
          }()

          if gridID == .outer {
            gridView.frame = .init(
              origin: .init(),
              size: outerGridSize
            )

          } else if let asssociatedWindow = grid.asssociatedWindow {
            switch asssociatedWindow {
            case let .plain(window):
              gridView.frame = (window.frame * font.cellSize)
                .applying(upsideDownTransform)

            default:
              gridView.frame = .init()
            }

          } else {
            gridView.frame = .init()
          }

          gridView.isHidden = grid.isHidden

          if let updatedRectangles = updates?.gridUpdatedRectangles[gridID] {
            for rectangle in updatedRectangles {
              let rect = rectangle * font.cellSize
                .applying(
                  .init(scaleX: 1, y: -1)
                    .translatedBy(x: 0, y: -gridView.frame.size.height)
                )
              gridView.setNeedsDisplay(rect)
            }
          }

        } else {
          gridViews[gridID]?.removeFromSuperview()
          gridViews.removeValue(forID: gridID)
        }
      }
    }
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
