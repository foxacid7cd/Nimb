// SPDX-License-Identifier: MIT

import IdentifiedCollections
import Library
import Neovim
import SwiftUI
import TinyConstraints

class CmdlinesWindowController: NSWindowController, NSWindowDelegate {
  private let store: Store
  private let parentWindow: NSWindow
  private let viewController: CmdlinesViewController
  private var task: Task<Void, Never>?

  init(store: Store, parentWindow: NSWindow) {
    self.store = store
    self.parentWindow = parentWindow

    viewController = CmdlinesViewController(store: store)

    let window = Window(contentViewController: viewController)
    window.styleMask = [.titled, .fullSizeContentView]
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovable = false
    window.isOpaque = false
    window.setIsVisible(false)
    window.contentMaxSize = CGSize(width: Double.greatestFiniteMagnitude, height: 200)

    super.init(window: window)

    window.delegate = self

    task = Task { [weak self] in
      for await stateUpdates in store.stateUpdatesStream() {
        guard let self, !Task.isCancelled else {
          break
        }

        if stateUpdates.isCmdlinesUpdated || stateUpdates.isAppearanceUpdated || stateUpdates.isFontUpdated {
          updateWindow()
        }
      }
    }
  }

  deinit {
    task?.cancel()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func updateWindow() {
    guard let window else {
      return
    }

    viewController.reloadData()

    if store.cmdlines.dictionary.isEmpty {
      parentWindow.removeChildWindow(window)
      window.setIsVisible(false)

    } else {
      parentWindow.addChildWindow(window, ordered: .above)
    }
  }

  func windowDidResize(_: Notification) {
    window!.setFrameOrigin(
      .init(
        x: parentWindow.frame.origin.x + (parentWindow.frame.width / 2) - (window!.frame.width / 2),
        y: parentWindow.frame.origin.y + (parentWindow.frame.height / 1.5) - (window!.frame.height / 2)
      )
    )
  }
}

private final class Window: NSWindow {
  override var canBecomeKey: Bool {
    false
  }

  override var canBecomeMain: Bool {
    false
  }
}

private final class CmdlinesViewController: NSViewController {
  func reloadData() {
    contentView.arrangedSubviews
      .forEach(contentView.removeView(_:))

    let cmdlines = store.cmdlines.dictionary.values
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

  private let store: Store
  private let scrollView = NSScrollView()
  private let contentView = NSStackView(views: [])

  init(store: Store) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let view = NSView(frame: .zero)

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

    let scrollViewHeightConstraint = scrollView.height(to: view)
    scrollViewHeightConstraint.priority = .defaultLow

    contentView.orientation = .vertical
    contentView.spacing = 0
    contentView.distribution = .fill
    contentView.edgeInsets = .init()
    scrollView.documentView = contentView

    contentView.width(to: scrollView)
    scrollView.width(500)
    scrollView.height(max: 160)
    let scrollViewToContentHeightConstraint = scrollView.height(to: contentView)
    scrollViewToContentHeightConstraint.priority = .init(rawValue: 749)

    self.view = view
  }
}

private final class CmdlineView: NSView {
  private let store: Store

  private let promptTextField = NSTextField(labelWithString: "")
  private let firstCharacterView: CmdlineFirstCharacterView
  private let contentTextView: CmdlineTextView

  private var promptToContentConstraint: NSLayoutConstraint?
  private var firstCharacterToContentConstraint: NSLayoutConstraint?
  private var contentToTopConstraint: NSLayoutConstraint?
  private var contentToLeadingConstraint: NSLayoutConstraint?

  init(store: Store) {
    self.store = store
    contentTextView = .init(store: store)
    firstCharacterView = .init(store: store)
    super.init(frame: .zero)

    promptTextField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(promptTextField)

    firstCharacterView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(firstCharacterView)

    contentTextView.translatesAutoresizingMaskIntoConstraints = false
    contentTextView.setContentHuggingPriority(.init(rawValue: 999), for: .vertical)
    addSubview(contentTextView)

    addConstraints([
      promptTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      promptTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 8),
      promptTextField.topAnchor.constraint(equalTo: topAnchor, constant: 8),

      firstCharacterView.widthAnchor.constraint(equalToConstant: 20),
      firstCharacterView.heightAnchor.constraint(equalToConstant: 20),
      firstCharacterView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      firstCharacterView.firstBaselineAnchor.constraint(equalTo: contentTextView.firstBaselineAnchor),

      contentTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      contentTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
    ])

    promptToContentConstraint = promptTextField.bottomAnchor.constraint(equalTo: contentTextView.topAnchor, constant: 8)
    promptToContentConstraint!.priority = .defaultHigh

    firstCharacterToContentConstraint = firstCharacterView.trailingAnchor.constraint(
      equalTo: contentTextView.leadingAnchor,
      constant: -8
    )
    firstCharacterToContentConstraint!.priority = .defaultHigh

    contentToTopConstraint = contentTextView.topAnchor.constraint(equalTo: topAnchor, constant: 8)
    contentToTopConstraint!.priority = .defaultHigh

    contentToLeadingConstraint = contentTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
    contentToLeadingConstraint!.priority = .defaultHigh
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func update(cmdline: Cmdline, blockLines: [[Cmdline.ContentPart]]) {
    if !cmdline.prompt.isEmpty {
      promptTextField.attributedStringValue = .init(string: cmdline.prompt, attributes: [
        .foregroundColor: NSColor.textColor,
        .font: store.font.nsFont(isItalic: true),
      ])

      firstCharacterView.isHidden = true
      promptTextField.isHidden = false

      promptToContentConstraint!.isActive = true
      firstCharacterToContentConstraint!.isActive = false
      contentToTopConstraint!.isActive = false
      contentToLeadingConstraint!.isActive = true

    } else {
      firstCharacterView.firstCharacter = cmdline.firstCharacter
      firstCharacterView.render()

      firstCharacterView.isHidden = false
      promptTextField.isHidden = true

      promptToContentConstraint!.isActive = false
      firstCharacterToContentConstraint!.isActive = true
      contentToTopConstraint!.isActive = true
      contentToLeadingConstraint!.isActive = false
    }

    let accumulator = NSMutableAttributedString()

    for blockLine in blockLines {
      let lineAccumulator = NSMutableAttributedString()

      for contentPart in blockLine {
        lineAccumulator.append(
          attributedString(forContentPart: contentPart)
        )
      }

      accumulator.append(lineAccumulator)
      accumulator.append(.init(string: "\n"))
    }

    let lineAccumulator = NSMutableAttributedString()
    lineAccumulator.append(.init(
      string: "".padding(
        toLength: cmdline.indent,
        withPad: " ",
        startingAt: 0
      )
    ))
    for contentPart in cmdline.contentParts {
      lineAccumulator.append(
        attributedString(forContentPart: contentPart)
      )
    }
    lineAccumulator.append(.init(string: " "))
    accumulator.append(lineAccumulator)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = .byCharWrapping
    paragraphStyle.allowsDefaultTighteningForTruncation = false
    accumulator.addAttribute(
      .paragraphStyle,
      value: paragraphStyle,
      range: .init(location: 0, length: accumulator.length)
    )

    contentTextView.blockLines = blockLines
    contentTextView.cmdline = cmdline
    contentTextView.render()
  }

  private func attributedString(forContentPart contentPart: Cmdline.ContentPart) -> NSAttributedString {
    .init(
      string: contentPart.text,
      attributes: .init([
        .font: store.font.nsFont(),
        .foregroundColor: store.appearance.foregroundColor(for: contentPart.highlightID).appKit,
      ])
    )
  }
}

private final class CmdlineFirstCharacterView: NSView {
  var firstCharacter = ""

  func render() {
    let attributedString = NSAttributedString(string: firstCharacter, attributes: [
      .font: store.font.nsFont(isBold: true),
      .foregroundColor: NSColor.textColor,
    ])
    let stringRange = CFRange(location: 0, length: attributedString.length)
    let ctFramesetter = CTFramesetterCreateWithAttributedString(attributedString)
    let boundingSize = CTFramesetterSuggestFrameSizeWithConstraints(
      ctFramesetter,
      stringRange,
      nil,
      bounds.size,
      nil
    )

    let size = CGSize(
      width: bounds.width,
      height: ceil(boundingSize.height)
    )
    let origin = CGPoint(
      x: (bounds.width - boundingSize.width) / 2,
      y: (bounds.height - size.height) / 2
    )
    ctFrameYOffset = origin.y

    ctFrame = CTFramesetterCreateFrame(
      ctFramesetter,
      stringRange,
      .init(
        rect: .init(origin: origin, size: size),
        transform: nil
      ),
      nil
    )

    backgroundColor = .init(hueSource: firstCharacter, saturation: 0.95, brightness: 0.8, alpha: 0.6)
  }

  override var frame: NSRect {
    didSet {
      if frame.size != oldValue.size {
        render()
      }
    }
  }

  private let store: Store
  private var ctFrame: CTFrame?
  private var backgroundColor: NSColor?
  private var ctFrameYOffset: Double = 0

  init(store: Store) {
    self.store = store
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_: NSRect) {
    let graphicsContext = NSGraphicsContext.current!
    let cgContext = graphicsContext.cgContext

    cgContext.saveGState()
    defer { cgContext.restoreGState() }

    if let backgroundColor {
      backgroundColor.setFill()
      cgContext.addPath(
        .init(roundedRect: bounds, cornerWidth: 5, cornerHeight: 5, transform: nil)
      )
      cgContext.fillPath()
    }

    if let ctFrame {
      cgContext.textMatrix = .identity
      CTFrameDraw(ctFrame, cgContext)
    }
  }

  override var firstBaselineOffsetFromTop: CGFloat {
    store.font.nsFont().ascender + ctFrameYOffset
  }
}

private final class CmdlineTextView: NSView {
  var blockLines = [[Cmdline.ContentPart]]()
  var cmdline: Cmdline?

  func render() {
    guard let cmdline else {
      return
    }

    let attributedString = NSMutableAttributedString()

    for contentParts in blockLines {
      let lineAttributedString = NSMutableAttributedString()

      for contentPart in contentParts {
        lineAttributedString.append(.init(
          string: contentPart.text,
          attributes: .init([
            .font: store.font.nsFont(),
            .foregroundColor: store.appearance.foregroundColor(for: contentPart.highlightID).appKit,
          ])
        ))
      }

      attributedString.append(lineAttributedString)
      lineAttributedString.append(
        .init(string: "\n", attributes: [.font: store.font.nsFont()])
      )
    }

    if cmdline.indent > 0 {
      let prefix = "".padding(
        toLength: cmdline.indent,
        withPad: " ",
        startingAt: 0
      )
      attributedString.append(
        .init(string: prefix, attributes: [.font: store.font.nsFont()])
      )
    }

    let lineAttributedString = NSMutableAttributedString()
    for contentPart in cmdline.contentParts {
      lineAttributedString.append(.init(
        string: contentPart.text,
        attributes: .init([
          .font: store.font.nsFont(),
          .foregroundColor: store.appearance.foregroundColor(for: contentPart.highlightID).appKit,
        ])
      ))
    }
    lineAttributedString.append(
      .init(string: " ", attributes: [.font: store.font.nsFont()])
    )
    if !cmdline.specialCharacter.isEmpty {
      lineAttributedString.insert(
        .init(
          string: cmdline.specialCharacter,
          attributes: [
            .font: store.font.nsFont(),
            .foregroundColor: store.appearance.defaultSpecialColor.appKit,
          ]
        ),
        at: cmdline.cursorPosition
      )
    } else {
      lineAttributedString.addAttributes(
        [
          .foregroundColor: store.appearance.defaultBackgroundColor.appKit,
          .backgroundColor: store.appearance.defaultForegroundColor.appKit,
        ],
        range: .init(location: cmdline.cursorPosition, length: 1)
      )
    }
    attributedString.append(lineAttributedString)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = .byCharWrapping
    paragraphStyle.allowsDefaultTighteningForTruncation = false
    attributedString.addAttribute(
      .paragraphStyle,
      value: paragraphStyle,
      range: .init(location: 0, length: attributedString.length)
    )

    let stringRange = CFRange(location: 0, length: attributedString.length)
    let containerSize = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)

    let ctFramesetter = CTFramesetterCreateWithAttributedString(attributedString)
    let boundingSize = CTFramesetterSuggestFrameSizeWithConstraints(
      ctFramesetter,
      stringRange,
      nil,
      containerSize,
      nil
    )
    invalidateIntrinsicContentSize()

    let path = CGPath(
      rect: .init(
        origin: .zero,
        size: .init(width: containerSize.width, height: ceil(boundingSize.height))
      ),
      transform: nil
    )
    let ctFrame = CTFramesetterCreateFrame(ctFramesetter, stringRange, path, nil)
    ctLines = CTFrameGetLines(ctFrame) as! [CTLine]

    setNeedsDisplay(bounds)
  }

  private let store: Store
  private var ctLines = [CTLine]()

  init(store: Store) {
    self.store = store
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_: NSRect) {
    let graphicsContext = NSGraphicsContext.current!
    let cgContext = graphicsContext.cgContext

    cgContext.saveGState()
    defer { cgContext.restoreGState() }

    let font = store.font.nsFont()
    for (offset, ctLine) in ctLines.reversed().enumerated() {
      cgContext.textMatrix = .init(
        translationX: 0,
        y: Double(offset) * store.font.cellHeight - font.descender
      )
      CTLineDraw(ctLine, cgContext)
    }
  }

  override var intrinsicContentSize: NSSize {
    .init(
      width: frame.width,
      height: Double(ctLines.count) * store.font.cellHeight
    )
  }

  override var frame: NSRect {
    didSet {
      if oldValue.width != frame.width {
        render()
      }
    }
  }

  override var firstBaselineOffsetFromTop: CGFloat {
    store.font.nsFont().ascender
  }
}
