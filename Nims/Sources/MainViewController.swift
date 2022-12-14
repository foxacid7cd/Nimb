// Copyright © 2022 foxacid7cd. All rights reserved.

import Cocoa

@MainActor
class MainViewController: NSViewController {
  init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = NSView(frame: .zero)
  }

  func apply(_ update: Store.Update) async {
    switch update {
    case .cellSize:
      for view in view.subviews {
        guard let gridView = view as? GridView else {
          continue
        }

        await updateFrame(for: gridView, with: gridView.grid)
      }

    case let .newGrid(grid):
      let gridView = GridView(store: store, grid: grid)
      await updateFrame(for: gridView, with: grid)

      view.addSubview(gridView)

      for await gridUpdate in grid.updates {
        guard !Task.isCancelled else {
          return
        }

        switch gridUpdate {
        case .size:
          await updateFrame(for: gridView, with: grid)

        case let .row(origin, width):
          let rectangle = Rectangle(
            origin: origin,
            size: .init(
              width: width,
              height: 1
            )
          )
          await gridView.drawGrid(at: rectangle)
        }
      }
    }
  }

  @MainActor
  private class GridView: NSView {
    init(store: Store, grid: Grid) {
      self.store = store
      self.grid = grid
      super.init(frame: .init())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    let grid: Grid

    func drawGrid(at rectangle: Rectangle) async {
      let cellSize = await store.cellSize

      setNeedsDisplay(rectangle * cellSize)
    }

    private let store: Store
  }

  private let store: Store
  private var updatesTask: Task<Void, Never>?

  private func updateFrame(for gridView: GridView, with grid: Grid) async {
    let gridSize = grid.size
    let cellSize = await store.cellSize

    let size = gridSize * cellSize
    gridView.frame = .init(
      origin: .init(),
      size: size
    )

    if grid.id == 1 {
      set(preferredContentSize: size)
    }
  }

  private func set(preferredContentSize: CGSize) {
    self.preferredContentSize = preferredContentSize
  }
}
