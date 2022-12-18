//
//  Multigrid.swift
//  Nims
//
//  Created by Yevhenii Matviienko on 17.12.2022.
//

import ComposableArchitecture
import SwiftUI

struct Multigrid: View {
  private var store: StoreOf<Reducer>

  init(
    store: StoreOf<Reducer>
  ) {
    self.store = store
  }

  var body: some View {
    WithViewStore(store, observe: \.windowSize) { windowSizeStore in
      ZStack(alignment: .topLeading) {
        WithViewStore(store, observe: \.gridRefs) { gridRefsStore in
          ForEach(gridRefsStore.state) { gridRef in
            Text(verbatim: "ID: \(gridRef.id.rawValue)")
              .zIndex(Double(gridRef.index))
          }
        }
      }
      .fixedSize()
      .frame(
        width: windowSizeStore.width,
        height: windowSizeStore.height
      )
    }
  }
}

struct GridRef: Equatable, Identifiable {
  var index: Int
  var id: Grid.ID
}

extension State {
  fileprivate var gridRefs: [GridRef] {
    grids
      .map(\.id)
      .enumerated()
      .map(GridRef.init(index:id:))
  }

  @MainActor
  fileprivate var windowSize: CGSize {
    guard let outerGrid else {
      return .init()
    }

    return outerGrid.cells.size * font.cellSize
  }
}
