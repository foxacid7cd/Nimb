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
  public init(store: Store<Model, Action>) {
    self.store = store
    viewStore = .init(
      store,
      observe: { $0 },
      removeDuplicates: { $0.gridsLayoutUpdateFlag == $1.gridsLayoutUpdateFlag }
    )
  }

  public var store: Store<Model, Action>

  public struct Model {
    public init(
      outerGridSize: IntegerSize,
      modeInfo: ModeInfo,
      mode: Mode,
      tabline: Tabline?,
      grids: IdentifiedArrayOf<Grid>,
      windows: IdentifiedArrayOf<Window>,
      floatingWindows: IdentifiedArrayOf<FloatingWindow>,
      cursor: Cursor?,
      cmdlines: IdentifiedArrayOf<Cmdline>,
      cmdlineUpdateFlag: Bool,
      gridsLayoutUpdateFlag: Bool,
      reportMouseEvent: @escaping (MouseEvent) -> Void
    ) {
      self.outerGridSize = outerGridSize
      self.modeInfo = modeInfo
      self.mode = mode
      self.tabline = tabline
      self.grids = grids
      self.windows = windows
      self.floatingWindows = floatingWindows
      self.cursor = cursor
      self.cmdlines = cmdlines
      self.cmdlineUpdateFlag = cmdlineUpdateFlag
      self.gridsLayoutUpdateFlag = gridsLayoutUpdateFlag
      self.reportMouseEvent = reportMouseEvent
    }

    public var outerGridSize: IntegerSize
    public var modeInfo: ModeInfo
    public var mode: Mode
    public var tabline: Tabline?
    public var grids: IdentifiedArrayOf<Grid>
    public var windows: IdentifiedArrayOf<Window>
    public var floatingWindows: IdentifiedArrayOf<FloatingWindow>
    public var cursor: Cursor?
    public var cmdlines: IdentifiedArrayOf<Cmdline>
    public var cmdlineUpdateFlag: Bool
    public var gridsLayoutUpdateFlag: Bool
    public var reportMouseEvent: (MouseEvent) -> Void

    var headerViewModel: HeaderView.Model {
      .init(
        tabline: tabline,
        gridsLayoutUpdateFlag: gridsLayoutUpdateFlag
      )
    }

    func gridViewModel(for gridID: Grid.ID) -> GridView.Model {
      .init(
        grid: grids[id: gridID]!,
        grids: grids,
        cursor: cursor,
        modeInfo: modeInfo,
        mode: mode,
        reportMouseEvent: reportMouseEvent
      )
    }

    var cmdlinesViewModel: CmdlinesView.Model {
      .init(
        cmdlines: cmdlines,
        cmdlineUpdateFlag: cmdlineUpdateFlag
      )
    }
  }

  public enum Action: Equatable {
    case header(action: HeaderView.Action)
    case grid(action: GridView.Action)
    case cmdlines(action: CmdlinesView.Action)
  }

  @Environment(\.nimsAppearance)
  private var nimsAppearance: NimsAppearance

  @ObservedObject
  private var viewStore: ViewStore<Model, Action>

  public var body: some View {
    let state = viewStore.state

    ZStack(alignment: .center) {
      VStack(spacing: 0) {
        HeaderView(
          store: store
            .scope(
              state: \.headerViewModel,
              action: Action.header(action:)
            )
        )
        .frame(height: 32)
        .background(nimsAppearance.defaultBackgroundColor.swiftUI)

        let outerGridSize = state.outerGridSize * nimsAppearance.font.cellSize
        let outerGridFrame = CGRect(origin: .init(), size: outerGridSize)

        ZStack(alignment: .topLeading) {
          GridView(
            store: store
              .scope(
                state: { $0.gridViewModel(for: .outer) },
                action: Action.grid(action:)
              )
          )
          .frame(width: outerGridSize.width, height: outerGridSize.height)
          .zIndex(0)

          ForEach(state.windows) { window in
            let frame = window.frame * nimsAppearance.font.cellSize
            let clippedFrame = frame.intersection(outerGridFrame)

            GridView(
              store: store
                .scope(
                  state: { $0.gridViewModel(for: window.gridID) },
                  action: Action.grid(action:)
                )
            )
            .frame(width: clippedFrame.width, height: clippedFrame.height)
            .offset(x: clippedFrame.minX, y: clippedFrame.minY)
            .zIndex(Double(window.zIndex) / 1000 + 1000)
            .opacity(window.isHidden ? 0 : 1)
          }

          ForEach(state.floatingWindows) { floatingWindow in
            let grid = state.grids[id: floatingWindow.gridID]!
            let frame = calculateFrame(
              for: floatingWindow,
              grid: grid
            )
            let clippedFrame = frame.intersection(outerGridFrame)

            GridView(
              store: store
                .scope(
                  state: { $0.gridViewModel(for: floatingWindow.gridID) },
                  action: Action.grid(action:)
                )
            )
            .frame(width: clippedFrame.width, height: clippedFrame.height)
            .offset(x: clippedFrame.minX, y: clippedFrame.minY)
            .zIndex(Double(floatingWindow.zIndex) / 1000 + 1_000_000)
            .opacity(floatingWindow.isHidden ? 0 : 1)
          }
        }
      }

      let cmdlinesStore = store.scope(
        state: \.cmdlinesViewModel,
        action: Action.cmdlines(action:)
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

  private func calculateFrame(
    for floatingWindow: FloatingWindow,
    grid: Grid
  )
    -> CGRect
  {
    let grids = viewStore.grids
    let anchorGrid = grids[id: floatingWindow.anchorGridID]!
    let windows = viewStore.windows
    let floatingWindows = viewStore.floatingWindows
    let cellSize = nimsAppearance.cellSize

    let anchorGridOrigin: CGPoint
    if let windowID = anchorGrid.windowID {
      if let window = windows[id: windowID] {
        anchorGridOrigin = window.frame.origin * cellSize

      } else {
        let floatingWindow = floatingWindows[id: windowID]!

        anchorGridOrigin = calculateFrame(
          for: floatingWindow,
          grid: grids[id: floatingWindow.gridID]!
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
