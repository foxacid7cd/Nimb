// SPDX-License-Identifier: MIT

import AppKit
import Neovim

final class CmdlineView: NSView {
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
      promptTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
      promptTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 10),
      promptTextField.topAnchor.constraint(equalTo: topAnchor, constant: 10),

      firstCharacterView.widthAnchor.constraint(equalToConstant: 20),
      firstCharacterView.heightAnchor.constraint(equalToConstant: 20),
      firstCharacterView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
      firstCharacterView.firstBaselineAnchor.constraint(equalTo: contentTextView.firstBaselineAnchor),

      contentTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      contentTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
    ])

    promptToContentConstraint = promptTextField.bottomAnchor.constraint(equalTo: contentTextView.topAnchor, constant: -4)
    promptToContentConstraint!.priority = .defaultHigh

    firstCharacterToContentConstraint = firstCharacterView.trailingAnchor.constraint(
      equalTo: contentTextView.leadingAnchor,
      constant: -8
    )
    firstCharacterToContentConstraint!.priority = .defaultHigh

    contentToTopConstraint = contentTextView.topAnchor.constraint(equalTo: topAnchor, constant: 10)
    contentToTopConstraint!.priority = .defaultHigh

    contentToLeadingConstraint = contentTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10)
    contentToLeadingConstraint!.priority = .defaultHigh
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func point(forCharacterLocation location: Int) -> CGPoint? {
    contentTextView.point(forCharacterLocation: location)
      .map { convert($0, from: contentTextView) }
  }

  func update(cmdline: Cmdline, blockLines: [[Cmdline.ContentPart]]) {
    if !cmdline.prompt.isEmpty {
      promptTextField.attributedStringValue = .init(string: cmdline.prompt, attributes: [
        .foregroundColor: store.appearance.defaultForegroundColor.appKit,
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

    contentTextView.blockLines = blockLines
    contentTextView.cmdline = cmdline
    contentTextView.render()
  }

  private let store: Store

  private let promptTextField = NSTextField(labelWithString: "")
  private let firstCharacterView: CmdlineFirstCharacterView
  private let contentTextView: CmdlineTextView

  private var promptToContentConstraint: NSLayoutConstraint?
  private var firstCharacterToContentConstraint: NSLayoutConstraint?
  private var contentToTopConstraint: NSLayoutConstraint?
  private var contentToLeadingConstraint: NSLayoutConstraint?

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
  init(store: Store) {
    self.store = store
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var firstCharacter = ""

  override var frame: NSRect {
    didSet {
      if frame.size != oldValue.size {
        render()
      }
    }
  }

  override var firstBaselineOffsetFromTop: CGFloat {
    store.font.nsFont().ascender + ctFrameYOffset
  }

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

  private let store: Store
  private var ctFrame: CTFrame?
  private var backgroundColor: NSColor?
  private var ctFrameYOffset: Double = 0
}

private final class CmdlineTextView: NSView {
  init(store: Store) {
    self.store = store
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var blockLines = [[Cmdline.ContentPart]]()
  var cmdline: Cmdline?

  override var intrinsicContentSize: NSSize {
    let linesCount = max(1, blockLineCTLines.count + cmdlineCTLines.count)

    return .init(
      width: frame.width,
      height: store.font.cellHeight * Double(linesCount)
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

  func render() {
    guard let cmdline else {
      return
    }

    let blockLinesAttributedString = NSMutableAttributedString()

    for (blockLineIndex, contentParts) in blockLines.enumerated() {
      let lineAttributedString = NSMutableAttributedString()

      for contentPart in contentParts {
        lineAttributedString.append(.init(
          string: contentPart.text
            .replacingOccurrences(of: "\r", with: "↲"),
          attributes: .init([
            .font: store.font.nsFont(),
            .foregroundColor: store.appearance.foregroundColor(for: contentPart.highlightID).appKit,
          ])
        ))
      }

      blockLinesAttributedString.append(lineAttributedString)

      if blockLineIndex < blockLines.count - 1 {
        blockLinesAttributedString.append(.init(
          string: "\n",
          attributes: [.font: store.font.nsFont()]
        ))
      }
    }

    let cmdlineAttributedString = NSMutableAttributedString()

    cmdlineAttributedString.append(.init(
      string: "".padding(
        toLength: cmdline.indent,
        withPad: " ",
        startingAt: 0
      ),
      attributes: [.font: store.font.nsFont()]
    ))

    for contentPart in cmdline.contentParts {
      cmdlineAttributedString.append(.init(
        string: contentPart.text
          .replacingOccurrences(of: "\r", with: "↲"),
        attributes: .init([
          .font: store.font.nsFont(),
          .foregroundColor: store.appearance.foregroundColor(for: contentPart.highlightID).appKit,
        ])
      ))
    }
    cmdlineAttributedString.append(.init(
      string: " ",
      attributes: [.font: store.font.nsFont()]
    ))
    if !cmdline.specialCharacter.isEmpty {
      cmdlineAttributedString.insert(
        .init(
          string: cmdline.specialCharacter,
          attributes: [
            .font: store.font.nsFont(),
            .foregroundColor: store.appearance.defaultSpecialColor.appKit,
          ]
        ),
        at: cmdline.cursorPosition + cmdline.indent
      )
    } else {
      cmdlineAttributedString.addAttributes(
        [
          .foregroundColor: store.appearance.defaultBackgroundColor.appKit,
          .backgroundColor: store.appearance.defaultForegroundColor.appKit,
        ],
        range: .init(location: cmdline.cursorPosition + cmdline.indent, length: 1)
      )
    }

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = .byCharWrapping

    blockLinesAttributedString.addAttribute(
      .paragraphStyle,
      value: paragraphStyle.copy(),
      range: .init(location: 0, length: blockLinesAttributedString.length)
    )
    cmdlineAttributedString.addAttribute(
      .paragraphStyle,
      value: paragraphStyle.copy(),
      range: .init(location: 0, length: cmdlineAttributedString.length)
    )

    func makeCTLines(for attributedString: NSAttributedString) -> [CTLine] {
      let ctFramesetter = CTFramesetterCreateWithAttributedString(attributedString)

      let stringRange = CFRange(location: 0, length: attributedString.length)
      let containerSize = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
      let boundingSize = CTFramesetterSuggestFrameSizeWithConstraints(
        ctFramesetter,
        stringRange,
        nil,
        containerSize,
        nil
      )
      let path = CGPath(
        rect: .init(
          origin: .zero,
          size: .init(width: containerSize.width, height: ceil(boundingSize.height))
        ),
        transform: nil
      )
      let ctFrame = CTFramesetterCreateFrame(ctFramesetter, stringRange, path, nil)

      return CTFrameGetLines(ctFrame) as! [CTLine]
    }
    blockLineCTLines = makeCTLines(for: blockLinesAttributedString)
    cmdlineCTLines = makeCTLines(for: cmdlineAttributedString)

    invalidateIntrinsicContentSize()
    setNeedsDisplay(bounds)
    displayIfNeeded()
  }

  func point(forCharacterLocation location: Int) -> CGPoint? {
    let location = location + (cmdline?.indent ?? 0)

    for ctLine in cmdlineCTLines.reversed() {
      let cfRange = CTLineGetStringRange(ctLine)
      let range = (cfRange.location ..< cfRange.location + cfRange.length)
      if range.contains(location) {
        return .init(
          x: CTLineGetOffsetForStringIndex(ctLine, location - cfRange.location, nil),
          y: 0
        )
      }
    }

    return nil
  }

  override func draw(_: NSRect) {
    let graphicsContext = NSGraphicsContext.current!
    let cgContext = graphicsContext.cgContext

    cgContext.saveGState()
    defer { cgContext.restoreGState() }

    let font = store.font.nsFont()
    let ctLines = (blockLineCTLines + cmdlineCTLines)
      .reversed()
    for (offset, ctLine) in ctLines.enumerated() {
      cgContext.textMatrix = .init(
        translationX: 0,
        y: Double(offset) * store.font.cellHeight - font.descender
      )
      CTLineDraw(ctLine, cgContext)
    }

    cgContext.flush()
  }

  private let store: Store
  private var blockLineCTLines = [CTLine]()
  private var cmdlineCTLines = [CTLine]()
}
