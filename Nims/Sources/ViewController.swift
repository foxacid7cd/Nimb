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
    init(_ viewModel: ViewModel?) {
      self.viewModel = viewModel
    }

    var body: some SwiftUI.View {
      if let viewModel {
        ZStack(alignment: .topLeading) {
          ForEach(viewModel.grids) { grid in
            Canvas { graphicsContext, size in
              let rect = CGRect(
                origin: .init(),
                size: size
              )
              graphicsContext.fill(
                Path(rect),
                with: .color(viewModel.defaultBackgroundColor),
                style: .init(antialiased: false)
              )

              for (y, row) in grid.rows.enumerated() {
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
                  Text(row.attributedString),
                  in: frame
                )
              }
            }
            .frame(width: grid.frame.width, height: grid.frame.height)
            .offset(x: grid.frame.origin.x, y: grid.frame.origin.y)
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

    private var viewModel: ViewModel?
  }

  override func loadView() {
    view = NSHostingView<View>(
      rootView: .init(nil)
    )
  }

  func render(viewModel: ViewModel, effects: [ViewModelEffect]) {
    hostingView.rootView = .init(viewModel)

    for effect in effects {
      switch effect {
      case .initial:
        break

      case .outerSizeChanged:
        preferredContentSize = viewModel.outerSize

      case .canvasChanged:
        break
      }
    }
  }

  private var hostingView: NSHostingView<View> {
    view as! NSHostingView<View>
  }
}
