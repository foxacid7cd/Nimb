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

        if isVisibleAnimatedOn != true {
          NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            view.animator().alphaValue = 1
          }
          view.isHidden = false
          isVisibleAnimatedOn = true
        }
      } else {
        if isVisibleAnimatedOn != false {
          NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            view.animator().alphaValue = 0
          } completionHandler: { [view] in
            view.isHidden = true
          }
          isVisibleAnimatedOn = false
        }
      }
    }

    if stateUpdates.isCursorBlinkingPhaseUpdated || stateUpdates.isBusyUpdated {
      for (_, cmdlineView) in cmdlineViews {
        cmdlineView.setNeedsDisplayTextView()
      }
    }
  }

  override public func loadView() {
    let view = NSView(frame: .zero)
    view.wantsLayer = true
    view.shadow = .init()
    view.layer!.cornerRadius = 8
    view.layer!.borderColor = NSColor.textColor.withAlphaComponent(0.2).cgColor
    view.layer!.borderWidth = 1
    view.layer!.shadowRadius = 5
    view.layer!.shadowOffset = .init(width: 4, height: -4)
    view.layer!.shadowOpacity = 0.2
    view.layer!.shadowColor = .black
    view.alphaValue = 0
    view.isHidden = true
    view.width(500)
    view.height(max: 160)

    let blurView = NSVisualEffectView()
    blurView.wantsLayer = true
    blurView.layer!.masksToBounds = true
    blurView.layer!.cornerRadius = 8
    blurView.blendingMode = .withinWindow
    blurView.material = .popover
    view.addSubview(blurView)
    blurView.edgesToSuperview()

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
  private var isVisibleAnimatedOn: Bool?
}
