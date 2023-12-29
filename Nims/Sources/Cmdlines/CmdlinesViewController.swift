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

  public func render(_ stateUpdates: State.Updates) {
    (view as! FloatingWindowView).render(stateUpdates)

    if stateUpdates.isCmdlinesUpdated {
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
            separatorView.alphaValue = 0.2
            separatorView.wantsLayer = true
            separatorView.layer!.backgroundColor = NSColor.textColor.cgColor
            contentView.addArrangedSubview(separatorView)
            separatorView.height(1)
            separatorView.width(to: contentView)
          }
        }
      }

      (view as! FloatingWindowView).animate(
        hide: store.state.cmdlines.dictionary.isEmpty
      )
    }

    if stateUpdates.isCursorBlinkingPhaseUpdated || stateUpdates.isMouseUserInteractionEnabledUpdated {
      for (_, cmdlineView) in cmdlineViews {
        cmdlineView.setNeedsDisplayTextView()
      }
    }
  }

  override public func loadView() {
    let view = FloatingWindowView(store: store)
    view.alphaValue = 0
    view.isHidden = true
    view.width(500)
    view.height(max: 160)

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

  private let store: Store
  private let scrollView = NSScrollView()
  private let contentView = NSStackView(views: [])
  private var cmdlineViews = IntKeyedDictionary<CmdlineView>()
}
