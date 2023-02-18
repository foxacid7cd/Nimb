// SPDX-License-Identifier: MIT

import CasePaths
import Collections
import ComposableArchitecture
import IdentifiedCollections
import Library
import Neovim
import Overture
import SwiftUI

@MainActor
public struct InstanceView: View {
  public init(
    model: InstanceViewModel,
    store: StoreOf<Instance>,
    mouseEventHandler: @escaping (MouseEvent) -> Void
  ) {
    self.model = model
    self.store = store
    self.mouseEventHandler = mouseEventHandler
  }

  public var model: InstanceViewModel
  public var store: StoreOf<Instance>
  public var mouseEventHandler: (MouseEvent) -> Void

  public var body: some View {
    WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: {
        $0.gridsLayoutUpdateFlag == $1.gridsLayoutUpdateFlag
      }
    ) { state in
      let outerGridSize = model.outerGridSize * model.font.cellSize
      let outerGridFrame = CGRect(origin: .init(), size: outerGridSize)

      ZStack(alignment: .topLeading) {
        GridView(
          gridID: .outer,
          instanceViewModel: model,
          store: store,
          mouseEventHandler: mouseEventHandler
        )
        .frame(width: outerGridSize.width, height: outerGridSize.height)
        .zIndex(0)

        ForEach(state.windows) { window in
          let frame = window.frame * model.font.cellSize
          let clippedFrame = frame.intersection(outerGridFrame)

          GridView(
            gridID: window.gridID,
            instanceViewModel: model,
            store: store,
            mouseEventHandler: mouseEventHandler
          )
          .frame(width: clippedFrame.width, height: clippedFrame.height)
          .offset(x: clippedFrame.minX, y: clippedFrame.minY)
          .zIndex(Double(window.zIndex) / 1000 + 1000)
          .opacity(window.isHidden ? 0 : 1)
        }

        ForEach(state.floatingWindows) { floatingWindow in
          let frame = calculateFrame(
            for: floatingWindow,
            grid: state.grids[id: floatingWindow.gridID]!,
            grids: state.grids,
            windows: state.windows,
            floatingWindows: state.floatingWindows,
            cellSize: model.font.cellSize
          )
          let clippedFrame = frame.intersection(outerGridFrame)

          GridView(
            gridID: floatingWindow.gridID,
            instanceViewModel: model,
            store: store,
            mouseEventHandler: mouseEventHandler
          )
          .frame(width: clippedFrame.width, height: clippedFrame.height)
          .offset(x: clippedFrame.minX, y: clippedFrame.minY)
          .zIndex(Double(floatingWindow.zIndex) / 1000 + 1_000_000)
          .opacity(floatingWindow.isHidden ? 0 : 1)
        }
      }
    }
  }

  private func calculateFrame(
    for floatingWindow: FloatingWindow,
    grid: Grid,
    grids: IdentifiedArrayOf<Grid>,
    windows: IdentifiedArrayOf<Window>,
    floatingWindows: IdentifiedArrayOf<FloatingWindow>,
    cellSize: CGSize
  )
    -> CGRect
  {
    let anchorGrid = grids[id: floatingWindow.anchorGridID]!

    let anchorGridOrigin: CGPoint
    if let windowID = anchorGrid.windowID {
      if let window = windows[id: windowID] {
        anchorGridOrigin = window.frame.origin * cellSize

      } else {
        let floatingWindow = floatingWindows[id: windowID]!

        anchorGridOrigin = calculateFrame(
          for: floatingWindow,
          grid: grids[id: floatingWindow.gridID]!,
          grids: grids,
          windows: windows,
          floatingWindows: floatingWindows,
          cellSize: cellSize
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
}
