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
      let state = viewStore.state

      let outerGridIntegerSize = state.outerGrid.cells.size
      let outerGridIntegerBounds = IntegerRectangle(size: outerGridIntegerSize)
      let outerGridSize = outerGridIntegerSize * nimsAppearance.cellSize
      let outerGridBounds = CGRect(origin: .init(), size: outerGridSize)

      ZStack(alignment: .topLeading) {
        VStack(spacing: 0) {
          HeaderView(
            store: store
              .scope(
                state: makeHeaderViewModel(from:),
                action: Instance.Action.headerView(action:)
              )
          )

          ZStack(alignment: .topLeading) {
            GridView(
              store: store
                .scope(
                  state: makeGridViewModel(gridID: .outer, integerSize: outerGridIntegerSize),
                  action: Instance.Action.gridView(action:)
                ),
              reportMouseEvent: reportMouseEvent
            )
            .frame(width: outerGridSize.width, height: outerGridSize.height)
            .zIndex(0)

            ForEach(state.windows) { window in
              let integerFrame = window.frame.intersection(
                with: outerGridIntegerBounds)
              let frame = integerFrame * nimsAppearance.cellSize

              GridView(
                store: store
                  .scope(
                    state: makeGridViewModel(gridID: window.gridID, integerSize: integerFrame.size),
                    action: Instance.Action.gridView(action:)
                  ),
                reportMouseEvent: reportMouseEvent
              )
              .frame(width: frame.width, height: frame.height)
              .offset(x: frame.minX, y: frame.minY)
              .zIndex(Double(window.zIndex) / 1000 + 1000)
              .opacity(window.isHidden ? 0 : 1)
            }

            ForEach(state.floatingWindows) { floatingWindow in
              let frame = calculateFrame(
                for: floatingWindow,
                grids: state.grids,
                windows: state.windows,
                floatingWindows: state.floatingWindows
              )
              .intersection(outerGridBounds)

              GridView(
                store: store
                  .scope(
                    state: makeGridViewModel(
                      gridID: floatingWindow.gridID,
                      integerSize: .init(
                        columnsCount: Int(ceil(frame.width / nimsAppearance.cellWidth)),
                        rowsCount: Int(ceil(frame.height / nimsAppearance.cellHeight))
                      )
                    ),
                    action: Instance.Action.gridView(action:)
                  ),
                reportMouseEvent: reportMouseEvent
              )
              .frame(width: frame.width, height: frame.height)
              .offset(x: frame.minX, y: frame.minY)
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

  public func makeGridViewModel(gridID: Grid.ID, integerSize: IntegerSize) -> (InstanceState) -> GridView.Model {
    { state in
      .init(
        gridID: gridID,
        integerSize: integerSize,
        grids: state.grids,
        cursor: state.cursor,
        modeInfo: state.modeInfo,
        mode: state.mode,
        cursorBlinkingPhase: !state.cmdlines.isEmpty || state.cursorBlinkingPhase
      )
    }
  }

  public func makeCmdlinesViewModel(for state: InstanceState) -> CmdlinesView.Model {
    .init(
      cmdlines: state.cmdlines,
      cmdlineUpdateFlag: state.cmdlineUpdateFlag
    )
  }
}
