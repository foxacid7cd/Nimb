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
  public init(store: StoreOf<RunningInstanceReducer>, reportMouseEvent: @escaping (MouseEvent) -> Void) {
    self.store = store
    self.reportMouseEvent = reportMouseEvent
  }

  private var store: StoreOf<RunningInstanceReducer>
  private var reportMouseEvent: (MouseEvent) -> Void

  @Environment(\.nimsFont)
  private var nimsFont: NimsFont

  public func makeNSView(context: Context) -> NSView {
    let view = NSView()
    view.bind(font: nimsFont, store: store, reportMouseEvent: reportMouseEvent)

    return view
  }

  public func updateNSView(_ nsView: NSView, context: Context) {}

  public final class NSView: AppKit.NSView {
    private var stateCancellable: AnyCancellable?
    private var font: NimsFont!
    private var store: StoreOf<RunningInstanceReducer>!
    private var reportMouseEvent: ((MouseEvent) -> Void)!
    private var viewStore: ViewStoreOf<RunningInstanceReducer>!

    private var state: Neovim.State {
      viewStore.state.stateContainer.state
    }

    public func bind(
      font: NimsFont,
      store: StoreOf<RunningInstanceReducer>,
      reportMouseEvent: @escaping (MouseEvent) -> Void
    ) {
      stateCancellable?.cancel()

      self.font = font
      self.store = store
      self.reportMouseEvent = reportMouseEvent

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
            new.translatesAutoresizingMaskIntoConstraints = false
            new.font = self.font
            new.stateContainer = self.viewStore.stateContainer
            new.gridID = gridID
            new.reportMouseEvent = reportMouseEvent
            self.addSubview(new)

            let widthConstraint = new.widthAnchor.constraint(equalToConstant: 0)
            widthConstraint.priority = .defaultHigh
            widthConstraint.isActive = true

            let heightConstraint = new.heightAnchor.constraint(equalToConstant: 0)
            heightConstraint.priority = .defaultHigh
            heightConstraint.isActive = true

            new.sizeConstraints = (widthConstraint, heightConstraint)

            gridViews[gridID] = new
            return new
          }()

          if gridID == .outer {
            gridView.sizeConstraints!.width.constant = outerGridSize.width
            gridView.sizeConstraints!.height.constant = outerGridSize.height

            gridView.floatingWindowConstraints?.horizontal.isActive = false
            gridView.floatingWindowConstraints?.vertical.isActive = false
            gridView.floatingWindowConstraints = nil

            if let constraints = gridView.windowConstraints {
              constraints.leading.constant = 0
              constraints.top.constant = 0

            } else {
              let leadingConstraint = gridView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
              leadingConstraint.priority = .defaultHigh
              leadingConstraint.isActive = true

              let topConstraint = gridView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
              topConstraint.priority = .defaultHigh
              topConstraint.isActive = true

              gridView.windowConstraints = (leadingConstraint, topConstraint)
            }

          } else if let associatedWindow = grid.associatedWindow {
            switch associatedWindow {
            case let .plain(value):
              let windowFrame = (value.frame * font.cellSize)

              gridView.sizeConstraints!.width.constant = windowFrame.width
              gridView.sizeConstraints!.height.constant = windowFrame.height

              gridView.floatingWindowConstraints?.horizontal.isActive = false
              gridView.floatingWindowConstraints?.vertical.isActive = false
              gridView.floatingWindowConstraints = nil

              if let constraints = gridView.windowConstraints {
                constraints.leading.constant = windowFrame.minX
                constraints.top.constant = windowFrame.minY

              } else {
                let leadingConstraint = gridView.leadingAnchor.constraint(
                  equalTo: leadingAnchor,
                  constant: windowFrame.minX
                )
                leadingConstraint.priority = .defaultHigh
                leadingConstraint.isActive = true

                let topConstraint = gridView.topAnchor.constraint(equalTo: topAnchor, constant: windowFrame.minY)
                topConstraint.priority = .defaultHigh
                topConstraint.isActive = true

                gridView.windowConstraints = (leadingConstraint, topConstraint)
              }

            case let .floating(value):
              let windowSize = grid.cells.size * font.cellSize
              gridView.sizeConstraints!.width.constant = windowSize.width
              gridView.sizeConstraints!.height.constant = windowSize.height

              gridView.windowConstraints?.leading.isActive = false
              gridView.windowConstraints?.top.isActive = false
              gridView.windowConstraints = nil

              gridView.floatingWindowConstraints?.horizontal.isActive = false
              gridView.floatingWindowConstraints?.vertical.isActive = false
              gridView.floatingWindowConstraints = nil

              let anchorGridView = gridViews[value.anchorGridID]!

              let horizontalConstant: Double = value.anchorColumn * font.cellWidth
              let verticalConstant: Double = value.anchorRow * font.cellHeight

              let horizontal: NSLayoutConstraint
              let vertical: NSLayoutConstraint

              switch value.anchor {
              case .northWest:
                horizontal = gridView.leadingAnchor.constraint(
                  equalTo: anchorGridView.leadingAnchor,
                  constant: horizontalConstant
                )
                vertical = gridView.topAnchor.constraint(
                  equalTo: anchorGridView.topAnchor,
                  constant: verticalConstant
                )

              case .northEast:
                horizontal = gridView.trailingAnchor.constraint(
                  equalTo: anchorGridView.leadingAnchor,
                  constant: horizontalConstant
                )
                vertical = gridView.topAnchor.constraint(
                  equalTo: anchorGridView.topAnchor,
                  constant: verticalConstant
                )

              case .southWest:
                horizontal = gridView.leadingAnchor.constraint(
                  equalTo: anchorGridView.leadingAnchor,
                  constant: horizontalConstant
                )
                vertical = gridView.bottomAnchor.constraint(
                  equalTo: anchorGridView.topAnchor,
                  constant: verticalConstant
                )

              case .southEast:
                horizontal = gridView.trailingAnchor.constraint(
                  equalTo: anchorGridView.leadingAnchor,
                  constant: horizontalConstant
                )
                vertical = gridView.bottomAnchor.constraint(
                  equalTo: anchorGridView.topAnchor,
                  constant: verticalConstant
                )
              }

              horizontal.isActive = true
              vertical.isActive = true
              gridView.floatingWindowConstraints = (horizontal, vertical)

            case .external:
              gridView.sizeConstraints!.width.constant = 0
              gridView.sizeConstraints!.height.constant = 0

              gridView.windowConstraints?.leading.isActive = false
              gridView.windowConstraints?.top.isActive = false
              gridView.windowConstraints = nil

              gridView.floatingWindowConstraints?.horizontal.isActive = false
              gridView.floatingWindowConstraints?.vertical.isActive = false
              gridView.floatingWindowConstraints = nil
            }

          } else {
            gridView.sizeConstraints!.width.constant = 0
            gridView.sizeConstraints!.height.constant = 0

            gridView.windowConstraints?.leading.isActive = false
            gridView.windowConstraints?.top.isActive = false
            gridView.windowConstraints = nil

            gridView.floatingWindowConstraints?.horizontal.isActive = false
            gridView.floatingWindowConstraints?.vertical.isActive = false
            gridView.floatingWindowConstraints = nil
          }

          gridView.isHidden = grid.isHidden

        } else {
          gridViews[gridID]?.removeFromSuperview()
          gridViews.removeValue(forID: gridID)
        }
      }

      if !updatedLayoutGridIDs.isEmpty {
        sortSubviews(
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
      }

      if let updates {
        for (gridID, updatedRectangles) in updates.gridUpdatedRectangles {
          guard let gridView = gridViews[gridID] else {
            continue
          }

          for rectangle in updatedRectangles {
            let rect = (rectangle * font.cellSize)
              .applying(
                .init(scaleX: 1, y: -1)
                  .translatedBy(x: 0, y: -gridView.frame.height)
              )

            gridView.setNeedsDisplay(rect)
          }
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
