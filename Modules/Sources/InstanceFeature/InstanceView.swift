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
  public init(store: StoreOf<Instance>, reportMouseEvent: @escaping (MouseEvent) -> Void) {
    self.store = store
    self.reportMouseEvent = reportMouseEvent
  }

  public var store: StoreOf<Instance>
  public var reportMouseEvent: (MouseEvent) -> Void

  @Environment(\.nimsAppearance)
  private var nimsAppearance: NimsAppearance

  public var body: some View {
    WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: {
        $0.gridsLayoutUpdateFlag == $1.gridsLayoutUpdateFlag
      }
    ) { viewStore in
      ZStack(alignment: .center) {
        VStack(spacing: 0) {
          HeaderView(
            store: store
              .scope(
                state: makeHeaderViewModel(from:),
                action: Instance.Action.headerView(action:)
              )
          )

          let outerGridSize = viewStore.outerGrid.map { $0.cells.size * nimsAppearance.cellSize } ?? .init(
            width: 640,
            height: 480
          )
          let outerGridFrame = CGRect(
            origin: .init(),
            size: outerGridSize
          )

          ZStack(alignment: .topLeading) {
            if viewStore.outerGrid != nil {
              GridView(
                store: store
                  .scope(
                    state: { makeGridViewModel(for: $0, gridID: .outer) },
                    action: Instance.Action.gridView(action:)
                  ),
                reportMouseEvent: reportMouseEvent
              )
              .frame(width: outerGridSize.width, height: outerGridSize.height)
              .zIndex(0)
            }

            ForEach(viewStore.windows) { window in
              let frame = window.frame * nimsAppearance.cellSize
              let clippedFrame = frame.intersection(outerGridFrame)

              GridView(
                store: store
                  .scope(
                    state: { makeGridViewModel(for: $0, gridID: window.gridID) },
                    action: Instance.Action.gridView(action:)
                  ),
                reportMouseEvent: reportMouseEvent
              )
              .frame(width: clippedFrame.width, height: clippedFrame.height)
              .offset(x: clippedFrame.minX, y: clippedFrame.minY)
              .zIndex(Double(window.zIndex) / 1000 + 1000)
              .opacity(window.isHidden ? 0 : 1)
            }

            ForEach(viewStore.floatingWindows) { floatingWindow in
              let frame = calculateFrame(
                for: floatingWindow,
                grids: viewStore.grids,
                windows: viewStore.windows,
                floatingWindows: viewStore.floatingWindows
              )
              let clippedFrame = frame.intersection(outerGridFrame)

              GridView(
                store: store
                  .scope(
                    state: { makeGridViewModel(for: $0, gridID: floatingWindow.gridID) },
                    action: Instance.Action.gridView(action:)
                  ),
                reportMouseEvent: reportMouseEvent
              )
              .frame(width: clippedFrame.width, height: clippedFrame.height)
              .offset(x: clippedFrame.minX, y: clippedFrame.minY)
              .zIndex(Double(floatingWindow.zIndex) / 1000 + 1_000_000)
              .opacity(floatingWindow.isHidden ? 0 : 1)
            }
          }
        }

        let cmdlinesStore = store.scope(
          state: makeCmdlinesViewModel(for:),
          action: Instance.Action.cmdlinesView(action:)
        )
        WithViewStore(
          cmdlinesStore,
          observe: { $0 },
          removeDuplicates: { $0.cmdlines.isEmpty == $1.cmdlines.isEmpty }
        ) { cmdlinesViewStore in
          if !cmdlinesViewStore.cmdlines.isEmpty {
            CmdlinesView(store: cmdlinesStore)
          }
        }
      }
    }
  }

  private func calculateFrame(
    for floatingWindow: FloatingWindow,
    grids: IntKeyedDictionary<Grid>,
    windows: IdentifiedArrayOf<Window>,
    floatingWindows: IdentifiedArrayOf<FloatingWindow>
  )
    -> CGRect
  {
    let grid = grids[floatingWindow.gridID]!
    let anchorGrid = grids[floatingWindow.anchorGridID]!
    let cellSize = nimsAppearance.cellSize

    let anchorGridOrigin: CGPoint
    if let windowID = anchorGrid.windowID {
      if let window = windows[id: windowID] {
        anchorGridOrigin = window.frame.origin * cellSize

      } else {
        let floatingWindow = floatingWindows[id: windowID]!

        anchorGridOrigin = calculateFrame(
          for: floatingWindow,
          grids: grids,
          windows: windows,
          floatingWindows: floatingWindows
        )
        .origin
      }

    } else {
      anchorGridOrigin = .init()
    }

    var frame = CGRect(
      origin: .init(
        x: anchorGridOrigin.x + (floatingWindow.anchorColumn * cellSize.width),
        y: anchorGridOrigin.y + (floatingWindow.anchorRow * cellSize.height)
      ),
      size: grid.cells.size * cellSize
    )

    switch floatingWindow.anchor {
    case .northWest:
      break

    case .northEast:
      frame.origin.x -= frame.size.width

    case .southWest:
      frame.origin.y -= frame.size.height

    case .southEast:
      frame.origin.x -= frame.size.width
      frame.origin.y -= frame.size.height
    }

    return frame
  }

  private func makeHeaderViewModel(from state: InstanceState) -> HeaderView.Model {
    .init(
      tabline: state.tabline,
      gridsLayoutUpdateFlag: state.gridsLayoutUpdateFlag
    )
  }

  public func makeGridViewModel(for state: InstanceState, gridID: Grid.ID) -> GridView.Model {
    .init(
      gridID: gridID,
      grids: state.grids,
      cursor: state.cursor,
      modeInfo: state.modeInfo,
      mode: state.mode,
      cursorBlinkingPhase: state.cursorBlinkingPhase
    )
  }

  public func makeCmdlinesViewModel(for state: InstanceState) -> CmdlinesView.Model {
    .init(
      cmdlines: state.cmdlines,
      cmdlineUpdateFlag: state.cmdlineUpdateFlag
    )
  }
}
