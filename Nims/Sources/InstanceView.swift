//
//  InstanceView.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 28.12.2022.
//

import CasePaths
import ComposableArchitecture
import NimsModel
import Overture
import SwiftUI

@MainActor
public struct InstanceView: View {
  public var store: Store<State.Instance, Action>

  public init(store: Store<State.Instance, Action>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: InstanceViewModel.init(state:)) { state in
      ZStack(alignment: .topLeading) {
        ForEach(state.grids) { grid in
          Canvas { graphicsContext, size in
            let rect = CGRect(origin: .init(), size: size)
            graphicsContext.fill(Path(rect), with: .color(grid.id.isOuter ? .orange : .cyan))
          }
          .frame(width: grid.size.width, height: grid.size.height)
          .zIndex(grid.zIndex)
        }
      }
      .frame(
        width: state.windowWidth,
        height: state.windowHeight
      )
    }
  }
}

public struct InstanceViewModel: Sendable, Equatable {
  public var windowWidth: Double
  public var windowHeight: Double
  public var grids: [ViewGrid]

  public init(windowWidth: Double, windowHeight: Double, grids: [ViewGrid]) {
    self.windowWidth = windowWidth
    self.windowHeight = windowHeight
    self.grids = grids
  }

  public init(
    state: State.Instance
  ) {
    let outerGrid = state.outerGrid

    windowWidth = Double(outerGrid.cells.size.columnsCount) * state.font.cellWidth
    windowHeight = Double(outerGrid.cells.size.rowsCount) * state.font.cellHeight
    grids = state.grids
      .enumerated()
      .map { (offset, grid) in
        ViewGrid(
          id: grid.id,
          zIndex: Double(offset),
          size: .zero
        )
      }
  }

  public struct ViewGrid: Sendable, Equatable, Identifiable {
    public var id: State.Grid.ID
    public var zIndex: Double
    public var size: CGSize

    public init(id: State.Grid.ID, zIndex: Double, size: CGSize) {
      self.id = id
      self.zIndex = zIndex
      self.size = size
    }
  }
}
