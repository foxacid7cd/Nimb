// SPDX-License-Identifier: MIT

import AppKit
import Library
import TinyConstraints

public class CmdlinesViewController: NSViewController {
  public init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var animatingToggling: ((_ on: Bool, _ animationDuration: Double) -> Void)? {
    get {
      customView.animatingToggling
    }
    set(value) {
      customView.animatingToggling = value
    }
  }

  public func render(_ stateUpdates: State.Updates) {
    if
      stateUpdates.isAppearanceUpdated,
      stateUpdates.updatedObservedHighlightNames
        .contains(where: CmdlinesViewController.observedHighlightName.contains(_:))
    {
      renderCustomView()
    }

    if stateUpdates.isCmdlinesUpdated || stateUpdates.isAppearanceUpdated {
      if !store.state.cmdlines.dictionary.isEmpty {
        cmdlineViews = [:]
        contentView.arrangedSubviews
          .forEach { $0.removeFromSuperview() }

        let cmdlines = store.state.cmdlines.dictionary.values
          .sorted(by: { $0.level < $1.level })

        for (index, cmdline) in cmdlines.enumerated() {
          let cmdlineView = CmdlineView(store: store, level: cmdline.level)
          contentView.addArrangedSubview(cmdlineView)
          cmdlineView.width(to: contentView)
          cmdlineViews[cmdline.level] = cmdlineView

          if index < cmdlines.count - 1 {
            let separatorView = NSView()
            separatorView.wantsLayer = true
            separatorView.layer!.backgroundColor = store.state.appearance.foregroundColor(for: .normalFloat)
              .with(alpha: 0.3)
              .appKit
              .cgColor
            contentView.addArrangedSubview(separatorView)
            separatorView.height(1)
            separatorView.width(to: contentView)
          }
        }
      }
    }

    if stateUpdates.isCursorBlinkingPhaseUpdated || stateUpdates.isMouseUserInteractionEnabledUpdated {
      for (_, cmdlineView) in cmdlineViews {
        cmdlineView.setNeedsDisplayTextView()
      }
    }

    if stateUpdates.isCmdlinesUpdated {
      let on = !store.state.cmdlines.dictionary.isEmpty
      customView.toggle(on: on, animationDuration: on ? 0.12 : 0.1)
    }
  }

  override public func loadView() {
    let view = customView
    view.width(452)
    view.height(max: 148)

    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = .init()
    scrollView.drawsBackground = false
    view.addSubview(scrollView)
    scrollView.edgesToSuperview()
    scrollView.height(to: view, priority: .defaultHigh)

    contentView.orientation = .vertical
    contentView.spacing = 0
    contentView.edgeInsets = .init()
    contentView.setHuggingPriority(.init(rawValue: 700), for: .vertical)
    contentView.setCompressionResistance(.init(rawValue: 900), for: .vertical)
    scrollView.documentView = contentView
    contentView.width(to: view)
    scrollView.height(to: contentView, priority: .init(rawValue: 700))

    self.view = view
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    customView.toggle(on: false)
    renderCustomView()
  }

  private static let observedHighlightName: Set<Appearance.ObservedHighlightName> = [.normalFloat, .special]

  private let store: Store
  private lazy var customView = FloatingWindowView(store: store)
  private lazy var scrollView = NSScrollView()
  private lazy var contentView = NSStackView(views: [])
  private var cmdlineViews = IntKeyedDictionary<CmdlineView>()

  private func renderCustomView() {
    customView.colors = (
      background: store.appearance.backgroundColor(for: .normalFloat),
      border: store.appearance.foregroundColor(for: .normalFloat).with(alpha: 0.3)
    )
    customView.render()
  }
}
