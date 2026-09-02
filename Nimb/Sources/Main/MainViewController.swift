// SPDX-License-Identifier: MIT

import AppKit
import NimbCore
import NimbNeovim
import NimbState

public class MainViewController: NSViewController, Rendering {
  public var renderContext: RenderContext! = nil

  let gridsView: GridsView

  private let store: Store
  private let minOuterGridSize: IntegerSize
  private lazy var tablineView = TablineView(store: store)
  private lazy var gridsContainerView = NSView()
  private lazy var loadingIndicator = NSProgressIndicator()
  private var preMaximizeWindowFrame: CGRect? = nil
  private lazy var visualBellView = NSView()
  private let reportOuterGridSizeChangedContinuation: AsyncStream<IntegerSize>.Continuation
  private var reportOuterGridSizeChangedTask: Task<Void, Never>? = nil

  init(store: Store, minOuterGridSize: IntegerSize) {
    self.store = store
    self.minOuterGridSize = minOuterGridSize
    gridsView = .init(store: store)
    let reportOuterGridSizeChanged: AsyncStream<IntegerSize>
    (
      reportOuterGridSizeChanged,
      reportOuterGridSizeChangedContinuation,
    ) = AsyncStream.makeStream()
    super.init(nibName: nil, bundle: nil)

    reportOuterGridSizeChangedTask = Task {
      let outerGridSizes = reportOuterGridSizeChanged
        .throttle(for: .milliseconds(50), clock: .continuous) { _, latest in latest }

      for await outerGridSize in outerGridSizes {
        store.api
          .fastCall(
            APIFunctions
              .NvimUITryResizeGrid(
                grid: Grid.OuterID,
                width: outerGridSize.columnsCount,
                height: outerGridSize.rowsCount,
              ),
          )
      }
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    reportOuterGridSizeChangedTask?.cancel()
  }

  override public func loadView() {
    let view = NSView()
    view.wantsLayer = true

    //    let visualEffectView = NSVisualEffectView()
    //    visualEffectView.blendingMode = .withinWindow
    //    visualEffectView.material = .titlebar

    //    visualEffectView.translatesAutoresizingMaskIntoConstraints = false
    //    view.addSubview(visualEffectView)
    //    visualEffectView.topToSuperview()
    //    visualEffectView.leading(to: view)
    //    visualEffectView.trailing(to: view)

    tablineView.setContentCompressionResistancePriority(
      .init(rawValue: 900),
      for: .vertical,
    )
    view.addSubview(tablineView)
    tablineView.topToSuperview()
    tablineView.leading(to: view)
    tablineView.trailing(to: view)

    let tablineDoubleClickGestureRecognizer = NSClickGestureRecognizer(
      target: self,
      action: #selector(handleTablineDoubleClick),
    )
    tablineDoubleClickGestureRecognizer.delaysPrimaryMouseButtonEvents = false
    tablineDoubleClickGestureRecognizer.numberOfClicksRequired = 2
    tablineView.addGestureRecognizer(tablineDoubleClickGestureRecognizer)

    let topSeparatorView = NSView()
    view.addSubview(topSeparatorView)
    topSeparatorView.topToBottom(of: tablineView)
    topSeparatorView.leading(to: view)
    topSeparatorView.trailing(to: view)
    topSeparatorView.height(1)
    topSeparatorView.wantsLayer = true
    topSeparatorView.layer!.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor

    view.addSubview(
      gridsContainerView,
      positioned: .below,
      relativeTo: tablineView,
    )
    gridsContainerView.translatesAutoresizingMaskIntoConstraints = false
    gridsContainerView.clipsToBounds = true
    gridsContainerView.topToBottom(of: topSeparatorView)
    gridsContainerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    gridsContainerView.setContentHuggingPriority(.defaultLow, for: .vertical)
    gridsContainerView.leading(to: view)
    gridsContainerView.trailing(to: view)
    gridsContainerView.bottomToSuperview()

    gridsContainerView.addSubview(gridsView)
    gridsView.centerXToSuperview()
    gridsView.topToSuperview()

    loadingIndicator.style = .spinning
    loadingIndicator.controlSize = .regular
    loadingIndicator.setAccessibilityLabel("Loading Neovim")
    gridsContainerView.addSubview(loadingIndicator)
    loadingIndicator.centerInSuperview()
    loadingIndicator.startAnimation(nil)

    visualBellView.wantsLayer = true
    visualBellView.layer!.backgroundColor = NSColor.white.cgColor
    visualBellView.layer!.opacity = 0
    view.addSubview(visualBellView)
    visualBellView.edgesToSuperview()

    self.view = view
  }

  override public func viewDidLayout() {
    super.viewDidLayout()

    if let window = view.window {
      let titleBarHeight = window.contentView!.frame.height - window
        .contentLayoutRect.height
      tablineView.preferredViewHeight = titleBarHeight
    }
  }

  public func render() {
    renderLoadingIndicator()

    if updates.isFontUpdated {
      reportOuterGridSizeChanged()
    }

    if updates.isAppearanceUpdated {
      renderBackground()
    }

    renderChildren(tablineView)

    if updates.isBellRung {
      NSSound.beep()
    }

    if updates.isVisualBellRung {
      flashVisualBell()
    }

    renderChildren(gridsView)
  }

  private func renderLoadingIndicator() {
    let isLoading = state.outerGrid == nil
    loadingIndicator.isHidden = !isLoading
    if isLoading {
      loadingIndicator.startAnimation(nil)
    } else {
      loadingIndicator.stopAnimation(nil)
    }
  }

  public func windowFrame(
    forGridID gridID: Grid.ID,
    gridFrame: IntegerRectangle,
  )
    -> CGRect?
  {
    gridsView.windowFrame(forGridID: gridID, gridFrame: gridFrame)
  }

  @discardableResult
  public func reportOuterGridSizeChanged() -> IntegerSize {
    let outerGridSize = IntegerSize(
      columnsCount: Int(gridsContainerView.frame.width / state.font.cellWidth),
      rowsCount: Int(gridsContainerView.frame.height / state.font.cellHeight),
    )
    reportOuterGridSizeChangedContinuation
      .yield(outerGridSize)
    return outerGridSize
  }

  private func flashVisualBell() {
    let animation = CABasicAnimation(keyPath: "opacity")
    animation.fromValue = 0.25
    animation.toValue = 0
    animation.duration = 0.12
    visualBellView.layer!.add(animation, forKey: "visualBell")
  }

  @objc private func handleTablineDoubleClick(_: NSClickGestureRecognizer) {
    guard let window = view.window, let screen = window.screen ?? .main else {
      return
    }

    let isMaximized = window.frame == screen.visibleFrame

    if !isMaximized {
      if window.frame != screen.visibleFrame {
        preMaximizeWindowFrame = window.frame
        window.setFrame(
          screen.visibleFrame,
          display: true,
          animate: true,
        )
      }

    } else {
      if let preMaximizeWindowFrame, window.frame != preMaximizeWindowFrame {
        window.setFrame(preMaximizeWindowFrame, display: true, animate: true)
      }
    }
  }

  private func renderBackground() {
    let backgroundCGColor = state.appearance.defaultBackgroundColor.appKit.cgColor
    view.layer!.backgroundColor = backgroundCGColor
    gridsView.layer!.backgroundColor = backgroundCGColor
  }
}
