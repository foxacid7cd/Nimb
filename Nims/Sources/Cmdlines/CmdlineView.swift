// SPDX-License-Identifier: MIT

import AppKit
import CustomDump

public class CmdlineView: NSView {
  public init(store: Store, level: Int) {
    self.level = level
    self.store = store
    firstCharacterView = .init(store: store, level: level)
    contentTextView = .init(store: store, level: level)
    cmdline = store.state.cmdlines.dictionary[level]!
    blockLines = store.state.cmdlines.blockLines[level] ?? []
    super.init(frame: .init())

    promptTextField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(promptTextField)

    firstCharacterView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(firstCharacterView)

    contentTextView.translatesAutoresizingMaskIntoConstraints = false
    contentTextView.setContentHuggingPriority(.init(rawValue: 999), for: .vertical)
    addSubview(contentTextView)

    addConstraints([
      promptTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
      promptTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      promptTextField.topAnchor.constraint(equalTo: topAnchor, constant: 10),

      firstCharacterView.topAnchor.constraint(equalTo: contentTextView.topAnchor),
      firstCharacterView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),

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

    render()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func render() {
    cmdline = store.state.cmdlines.dictionary[level]!
    blockLines = store.state.cmdlines.blockLines[level] ?? []

    if !cmdline.prompt.isEmpty {
      promptTextField.attributedStringValue = .init(string: cmdline.prompt, attributes: [
        .foregroundColor: store.state.appearance.foregroundColor(for: .normalFloat),
        .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
      ])

      firstCharacterView.isHidden = true
      promptTextField.isHidden = false

      promptToContentConstraint!.isActive = true
      firstCharacterToContentConstraint!.isActive = false
      contentToTopConstraint!.isActive = false
      contentToLeadingConstraint!.isActive = true

    } else {
      firstCharacterView.render()

      firstCharacterView.isHidden = false
      promptTextField.isHidden = true

      promptToContentConstraint!.isActive = false
      firstCharacterToContentConstraint!.isActive = true
      contentToTopConstraint!.isActive = true
      contentToLeadingConstraint!.isActive = false
    }

    contentTextView.cmdline = cmdline
    contentTextView.blockLines = blockLines
    contentTextView.render()
  }

  public func setNeedsDisplayTextView() {
    contentTextView.needsDisplay = true
  }

  private let store: Store
  private let level: Int
  private let promptTextField = NSTextField(labelWithString: "")
  private let firstCharacterView: CmdlineFirstCharacterView
  private let contentTextView: CmdlineTextView

  private var promptToContentConstraint: NSLayoutConstraint?
  private var firstCharacterToContentConstraint: NSLayoutConstraint?
  private var contentToTopConstraint: NSLayoutConstraint?
  private var contentToLeadingConstraint: NSLayoutConstraint?

  private var cmdline: Cmdline
  private var blockLines: [[Cmdline.ContentPart]]
}

private class CmdlineFirstCharacterView: NSView {
  init(store: Store, level: Int) {
    self.store = store
    self.level = level
    super.init(frame: .init())
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var frame: NSRect {
    didSet {
      if frame.size != oldValue.size {
        render()
      }
    }
  }

  override var intrinsicContentSize: NSSize {
    .init(width: store.font.cellHeight, height: store.font.cellHeight)
  }

  func render() {
    invalidateIntrinsicContentSize()

    let attributedString = NSAttributedString(string: firstCharacter, attributes: [
      .font: store.font.appKit(isBold: true),
      .foregroundColor: store.state.appearance.foregroundColor(for: .normalFloat).appKit,
    ])
    let stringRange = CFRange(location: 0, length: attributedString.length)
    let ctFramesetter = CTFramesetterCreateWithAttributedString(attributedString)
    let boundingSize = CTFramesetterSuggestFrameSizeWithConstraints(
      ctFramesetter,
      stringRange,
      nil,
      .init(width: store.font.cellWidth * 2, height: store.font.cellHeight * 2),
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
    ctFrame = CTFramesetterCreateFrame(
      ctFramesetter,
      stringRange,
      .init(
        rect: .init(origin: origin, size: size),
        transform: nil
      ),
      nil
    )

    backgroundColor = .init(
      hueSource: "".padding(
        toLength: firstCharacter.count * 4,
        withPad: firstCharacter,
        startingAt: 0
      ),
      saturation: 0.8,
      brightness: 0.8,
      alpha: 0.2
    )
  }

  override func draw(_: NSRect) {
    let context = NSGraphicsContext.current!.cgContext

    let path = CGPath(roundedRect: bounds, cornerWidth: 3, cornerHeight: 3, transform: nil)
    if let backgroundColor {
      backgroundColor.setFill()
      context.addPath(path)
      context.fillPath()
    }

    if let ctFrame {
      context.textMatrix = .identity
      CTFrameDraw(ctFrame, context)
    }
  }

  private let store: Store
  private let level: Int
  private var ctFrame: CTFrame?
  private var backgroundColor: NSColor?

  private var firstCharacter: String {
    store.state.cmdlines.dictionary[level]!.firstCharacter
  }
}

private class CmdlineTextView: NSView {
  init(store: Store, level: Int) {
    self.store = store
    self.level = level
    super.init(frame: .init())
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var cmdline: Cmdline?
  public var blockLines: [[Cmdline.ContentPart]]?

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

  func render() {
    guard let cmdline, let blockLines else {
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
            .font: store.font.appKit(),
            .foregroundColor: store.appearance.foregroundColor(for: contentPart.highlightID).appKit,
          ])
        ))
      }

      blockLinesAttributedString.append(lineAttributedString)

      if blockLineIndex < blockLines.count - 1 {
        blockLinesAttributedString.append(.init(
          string: "\n",
          attributes: [.font: store.font.appKit()]
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
      attributes: [.font: store.font.appKit()]
    ))

    cursorParentHighlightID = nil

    var location = 0
    for contentPart in cmdline.contentParts {
      var foregroundColor = store.appearance.foregroundColor(for: contentPart.highlightID)
      if foregroundColor == store.state.appearance.defaultForegroundColor {
        foregroundColor = store.state.appearance.foregroundColor(for: .normalFloat)
      }

      var attributes: [NSAttributedString.Key: Any] = [
        .font: store.font.appKit(),
        .foregroundColor: foregroundColor.appKit,
      ]

      let backgroundColor = store.appearance.backgroundColor(for: contentPart.highlightID)
      if backgroundColor != store.state.appearance.defaultBackgroundColor {
        attributes[.backgroundColor] = backgroundColor.appKit
      }

      cmdlineAttributedString.append(.init(
        string: contentPart.text
          .replacingOccurrences(of: "\r", with: "↲"),
        attributes: attributes
      ))
      if cmdline.cursorPosition >= location, cmdline.cursorPosition < location + contentPart.text.count {
        cursorParentHighlightID = contentPart.highlightID
      }
      location += contentPart.text.count
    }
    cmdlineAttributedString.append(.init(
      string: " ",
      attributes: [.font: store.font.appKit()]
    ))
    if !cmdline.specialCharacter.isEmpty {
      cmdlineAttributedString.insert(
        .init(
          string: cmdline.specialCharacter,
          attributes: [
            .font: store.font.appKit(),
            .foregroundColor: store.appearance.specialColor(for: .normalFloat).appKit,
          ]
        ),
        at: cmdline.cursorPosition + cmdline.indent
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

    func makeCTLines(for attributedString: NSAttributedString) -> (ctFramesetter: CTFramesetter, ctFrame: CTFrame, ctLines: [CTLine]) {
      let ctFramesetter = CTFramesetterCreateWithAttributedString(attributedString)

      let stringRange = CFRange(location: 0, length: 0)
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
      return (
        ctFramesetter,
        ctFrame,
        CTFrameGetLines(ctFrame) as! [CTLine]
      )
    }
    self.blockLinesAttributedString = blockLinesAttributedString
    self.cmdlineAttributedString = cmdlineAttributedString
    (blockLinesCTFramesetter, blockLinesCTFrame, blockLineCTLines) = makeCTLines(for: blockLinesAttributedString)
    (cmdlineCTFramesetter, cmdlineCTFrame, cmdlineCTLines) = makeCTLines(for: cmdlineAttributedString)

    invalidateIntrinsicContentSize()
    needsDisplay = true
  }

  override func draw(_: NSRect) {
    guard let cmdline else {
      return
    }
    let context = NSGraphicsContext.current!.cgContext

    var ctLineIndex = 0

    for cmdlineCTLine in cmdlineCTLines.reversed() {
      context.saveGState()
      context.textMatrix = .init(
        translationX: 0,
        y: Double(ctLineIndex) * store.font.cellHeight - store.font.appKit().descender
      )
      CTLineDraw(cmdlineCTLine, context)

      let range = CTLineGetStringRange(cmdlineCTLine)
      if
        store.state.cursorBlinkingPhase,
        !store.state.isBusy,
        cmdline.specialCharacter.isEmpty,
        let currentCursorStyle = store.state.currentCursorStyle,
        let highlightID = currentCursorStyle.attrID,
        let cellFrame = currentCursorStyle.cellFrame(columnsCount: 1, font: store.font),
        cmdline.cursorPosition >= range.location,
        cmdline.cursorPosition < range.location + range.length
      {
        let offset = CTLineGetOffsetForStringIndex(cmdlineCTLine, cmdline.cursorPosition, nil)
        let rect = cellFrame
          .offsetBy(
            dx: offset,
            dy: Double(ctLineIndex) * store.font.cellHeight
          )

        let cursorForegroundColor: NimsColor
        let cursorBackgroundColor: NimsColor

        if highlightID == Highlight.DefaultID, let cursorParentHighlightID {
          cursorForegroundColor = store.appearance.backgroundColor(for: cursorParentHighlightID)
          cursorBackgroundColor = NimsColor(rgb: 0xF0F0F0) // store.appearance.foregroundColor(for: cursorParentHighlightID)

        } else {
          cursorForegroundColor = store.appearance.foregroundColor(for: highlightID)
          cursorBackgroundColor = store.appearance.backgroundColor(for: highlightID)
        }

        context.saveGState()

        context.setShouldAntialias(false)
        context.setFillColor(cursorBackgroundColor.appKit.cgColor)
        context.fill([rect])

        if currentCursorStyle.shouldDrawParentText {
          context.setShouldAntialias(true)
          context.clip(to: [rect])
          context.setFillColor(cursorForegroundColor.appKit.cgColor)
          let glyphRuns = CTLineGetGlyphRuns(cmdlineCTLine) as! [CTRun]
          for glyphRun in glyphRuns {
            context.textMatrix = .init(
              translationX: 0,
              y: Double(ctLineIndex) * store.font.cellHeight - store.font.appKit().descender
            )
            CTFontDrawGlyphs(
              store.font.appKit(),
              CTRunGetGlyphsPtr(glyphRun)!,
              CTRunGetPositionsPtr(glyphRun)!,
              CTRunGetGlyphCount(glyphRun),
              context
            )
          }
        }

        context.restoreGState()
      }

      ctLineIndex += 1
      context.restoreGState()
    }

    for blockLineCTLine in blockLineCTLines.reversed() {
      context.saveGState()
      context.textMatrix = .init(
        translationX: 0,
        y: Double(ctLineIndex) * store.font.cellHeight - store.font.appKit().descender
      )
      CTLineDraw(blockLineCTLine, context)

      ctLineIndex += 1
      context.restoreGState()
    }
  }

  private let store: Store
  private let level: Int
  private var blockLinesAttributedString: NSAttributedString?
  private var cmdlineAttributedString: NSAttributedString?
  private var blockLinesCTFramesetter: CTFramesetter?
  private var cmdlineCTFramesetter: CTFramesetter?
  private var blockLinesCTFrame: CTFrame?
  private var cmdlineCTFrame: CTFrame?
  private var blockLineCTLines = [CTLine]()
  private var cmdlineCTLines = [CTLine]()
  private var cursorParentHighlightID: Highlight.ID?
}
