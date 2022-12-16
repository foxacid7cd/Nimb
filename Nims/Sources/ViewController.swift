// Copyright © 2022 foxacid7cd. All rights reserved.

import Cocoa
import Collections
import Combine
import SwiftUI

class ViewController: NSViewController {
  init() {
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  struct View: SwiftUI.View {
    let viewModel: ViewModel?

    var body: some SwiftUI.View {
      if let viewModel {
        ZStack(alignment: .topLeading) {
          ForEach(viewModel.grids) { grid in
            Canvas(opaque: false, rendersAsynchronously: true) { graphicsContext, size in
              let rect = CGRect(
                origin: .init(),
                size: grid.frame.size
              )
              graphicsContext.fill(
                Path(rect),
                with: .color(viewModel.defaultBackgroundColor),
                style: .init(antialiased: false)
              )

              for (y, attributedString) in grid.rowAttributedStrings.enumerated() {
                let frame = CGRect(
                  origin: .init(
                    x: 0,
                    y: Double(y) * viewModel.rowHeight
                  ),
                  size: .init(
                    width: grid.frame.width,
                    height: viewModel.rowHeight
                  )
                )

                graphicsContext.draw(
                  Text(attributedString),
                  in: frame
                )
              }

              if let cursor = viewModel.cursor, cursor.gridID == grid.id {
                graphicsContext.blendMode = .difference
                graphicsContext.fill(
                  Path(cursor.rect),
                  with: .color(Color.white),
                  style: .init(antialiased: false)
                )
              }
            }
            .frame(width: grid.frame.width, height: grid.frame.height)
            .offset(x: grid.frame.origin.x, y: grid.frame.origin.y)
            .zIndex(Double(grid.index))
          }
        }
        .frame(
          width: viewModel.outerSize.width,
          height: viewModel.outerSize.height
        )

      } else {
        EmptyView()
      }
    }

    private let font = NSFont(name: "MesloLGS NF", size: 13)!
  }

  override func loadView() {
    view = NSHostingView<View>(
      rootView:
      .init(viewModel: nil)
    )
  }

  func render(viewModel: ViewModel, effects: Set<ViewModelEffect>) {
    hostingView.rootView = .init(viewModel: viewModel)
  }

  private var hostingView: NSHostingView<View> {
    view as! NSHostingView<View>
  }
}
