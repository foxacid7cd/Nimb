// SPDX-License-Identifier: MIT

import AppKit
import TinyConstraints

final class CmdlinesViewController: NSViewController {
  init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func reloadData() {
    contentView.arrangedSubviews
      .forEach { $0.removeFromSuperview() }

    let cmdlines = store.cmdlines.dictionary.values
      .sorted(by: { $0.level < $1.level })

    for (cmdlineIndex, cmdline) in cmdlines.enumerated() {
      let blockLines = store.cmdlines.blockLines[cmdline.level] ?? []

      let cmdlineView = CmdlineView(store: store)
      cmdlineView.update(cmdline: cmdline, blockLines: blockLines)
      contentView.addArrangedSubview(cmdlineView)
      cmdlineView.width(to: contentView)

      if cmdlineIndex < cmdlines.count - 1 {
        let separatorView = NSView()
        separatorView.alphaValue = 0.15
        separatorView.wantsLayer = true
        separatorView.layer!.backgroundColor = NSColor.textColor.cgColor
        contentView.addArrangedSubview(separatorView)
        separatorView.height(1)
        separatorView.width(to: contentView)
      }
    }
  }

  func point(forCharacterLocation location: Int) -> CGPoint? {
    let cmdlineView = contentView.arrangedSubviews.last as! CmdlineView

    return cmdlineView
      .point(forCharacterLocation: location)
      .map { contentView.convert($0, from: cmdlineView) }
      .map { scrollView.convert($0, from: contentView) }
      .map { view.convert($0, from: scrollView) }
  }

  override func loadView() {
    let view = NSView(frame: .zero)
    view.width(500)
    view.height(max: 160)

    let blurView = NSVisualEffectView()
    blurView.blendingMode = .behindWindow
    blurView.state = .active
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
}
