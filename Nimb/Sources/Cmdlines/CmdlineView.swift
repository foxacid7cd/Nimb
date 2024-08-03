// SPDX-License-Identifier: MIT

import AppKit
import CustomDump

public class CmdlineView: NSView {
  public init(store: Store, level: Int) {
    self.level = level
    self.store = store
    contentTextView = .init(store: store, level: level)
    cmdline = store.state.cmdlines.dictionary[level]!
    blockLines = store.state.cmdlines.blockLines[level] ?? []
    super.init(frame: .init())

    promptTextField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(promptTextField)

    contentTextView.translatesAutoresizingMaskIntoConstraints = false
    contentTextView.setContentHuggingPriority(
      .init(rawValue: 999),
      for: .vertical
    )
    addSubview(contentTextView)

    promptConstraints = (
      promptTextField.leading(to: self, priority: .defaultHigh),
      promptTextField.trailing(to: self, priority: .defaultHigh),
      promptTextField.top(to: self, priority: .defaultHigh),
      promptTextField.bottomToTop(of: contentTextView, priority: .defaultHigh)
    )
    contentConstraints = (
      contentTextView.leading(to: self, priority: .defaultHigh),
      contentTextView.trailing(to: self, priority: .defaultHigh),
      contentTextView.top(to: self, priority: .defaultHigh),
      contentTextView.bottom(to: self, priority: .defaultHigh)
    )

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
      promptTextField.attributedStringValue = .init(
        string: cmdline.prompt,
        attributes: [
          .foregroundColor: NSColor.controlTextColor,
          .font: NSFont.systemFont(ofSize: NSFont.labelFontSize),
        ]
      )

      promptTextField.isHidden = false

      promptConstraints!.content.isActive = true
      contentConstraints!.top.isActive = false

    } else {
      promptTextField.isHidden = true

      promptConstraints!.content.isActive = false
      contentConstraints!.top.isActive = true
    }

    contentTextView.cmdline = cmdline
    contentTextView.blockLines = blockLines
    contentTextView.render()

    let horizontalInset: Double = 14
    let verticalInset: Double = 14
    let smallVerticalInset: Double = 3
    promptConstraints!.leading.constant = horizontalInset
    promptConstraints!.trailing.constant = -horizontalInset
    promptConstraints!.top.constant = verticalInset
    promptConstraints!.content.constant = -smallVerticalInset
    contentConstraints!.leading.constant = horizontalInset
    contentConstraints!.trailing.constant = -horizontalInset
    contentConstraints!.top.constant = verticalInset
    contentConstraints!.bottom.constant = -verticalInset
  }

  public func setNeedsDisplayTextView() {
    contentTextView.needsDisplay = true
  }

  private let store: Store
  private let level: Int
  private let promptTextField = NSTextField(labelWithString: "")
  private let contentTextView: CmdlineTextView
  private var promptConstraints: (
    leading: NSLayoutConstraint,
    trailing: NSLayoutConstraint,
    top: NSLayoutConstraint,
    content: NSLayoutConstraint
  )?
  private var contentConstraints: (
    leading: NSLayoutConstraint,
    trailing: NSLayoutConstraint,
    top: NSLayoutConstraint,
    bottom: NSLayoutConstraint
  )?
  private var cmdline: Cmdline
  private var blockLines: [[Cmdline.ContentPart]]
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

  public func render() {
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
            .foregroundColor: store.appearance
              .foregroundColor(for: contentPart.highlightID).appKit,
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
    indent = 0

    let prefix = "".padding(
      toLength: cmdline.indent,
      withPad: " ",
      startingAt: 0
    )
    cmdlineAttributedString.append(.init(
      string: prefix,
      attributes: [.font: store.font.appKit()]
    ))
    indent += prefix.count

    if !cmdline.firstCharacter.isEmpty {
      let text = "\(cmdline.firstCharacter) "
      cmdlineAttributedString.append(.init(
        string: text,
        attributes: [
          .font: store.font.appKit(isBold: true),
          .foregroundColor: NSColor.controlAccentColor,
        ]
      ))
      indent += text.count
    }

    let cursorPosition = indent + cmdline.cursorPosition

    var location = 0
    for contentPart in cmdline.contentParts {
      let attributes: [NSAttributedString.Key: Any] = [
        .font: store.font.appKit(),
        .foregroundColor: NSColor.secondaryLabelColor,
      ]

      cmdlineAttributedString.append(.init(
        string: contentPart.text
          .replacingOccurrences(of: "\r", with: "↲"),
        attributes: attributes
      ))
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
            .foregroundColor: NSColor.selectedControlColor,
          ]
        ),
        at: cursorPosition
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

    func makeCTLines(for attributedString: NSAttributedString)
      -> (ctFramesetter: CTFramesetter, ctFrame: CTFrame, ctLines: [CTLine])
    {
      let ctFramesetter =
        CTFramesetterCreateWithAttributedString(attributedString)

      let stringRange = CFRange(location: 0, length: 0)
      let containerSize = CGSize(
        width: bounds.width,
        height: .greatestFiniteMagnitude
      )
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
          size: .init(
            width: containerSize.width,
            height: ceil(boundingSize.height)
          )
        ),
        transform: nil
      )
      let ctFrame = CTFramesetterCreateFrame(
        ctFramesetter,
        stringRange,
        path,
        nil
      )
      return (
        ctFramesetter,
        ctFrame,
        CTFrameGetLines(ctFrame) as! [CTLine]
      )
    }
    self.blockLinesAttributedString = blockLinesAttributedString
    self.cmdlineAttributedString = cmdlineAttributedString
    (
      blockLinesCTFramesetter,
      blockLinesCTFrame,
      blockLineCTLines
    ) = makeCTLines(for: blockLinesAttributedString)
    (
      cmdlineCTFramesetter,
      cmdlineCTFrame,
      cmdlineCTLines
    ) = makeCTLines(for: cmdlineAttributedString)

    invalidateIntrinsicContentSize()
    setNeedsDisplay(bounds)
  }

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

  override func draw(_: NSRect) {
    guard let cmdline else {
      return
    }
    let appKitFont = store.font.appKit()
    let cursorPosition = indent + cmdline.cursorPosition
    let context = NSGraphicsContext.current!.cgContext

    var ctLineIndex = 0

    for cmdlineCTLine in cmdlineCTLines.reversed() {
      context.textMatrix = .init(
        translationX: 0,
        y: Double(ctLineIndex) * store.font.cellHeight - appKitFont.descender
      )
      CTLineDraw(cmdlineCTLine, context)

      let range = CTLineGetStringRange(cmdlineCTLine)
      if
        store.state.cursorBlinkingPhase,
        !store.state.isBusy,
        cmdline.specialCharacter.isEmpty,
        let currentCursorStyle = store.state.currentCursorStyle,
        let highlightID = currentCursorStyle.attrID,
        let cellFrame = currentCursorStyle.cellFrame(
          columnsCount: 1,
          font: store.font
        ),
        cursorPosition >= range.location,
        cursorPosition < range.location + range.length
      {
        let offset = CTLineGetOffsetForStringIndex(
          cmdlineCTLine,
          cursorPosition,
          nil
        )
        let rect = cellFrame
          .offsetBy(
            dx: offset,
            dy: Double(ctLineIndex) * store.font.cellHeight
          )

        let cursorForegroundColor: Color
        let cursorBackgroundColor: Color
        if highlightID == Highlight.defaultID {
          cursorForegroundColor = store.appearance.defaultBackgroundColor
          cursorBackgroundColor = store.appearance.defaultForegroundColor
        } else {
          cursorForegroundColor = store.appearance
            .foregroundColor(for: highlightID)
          cursorBackgroundColor = store.appearance
            .backgroundColor(for: highlightID)
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
            context.textMatrix = CTRunGetTextMatrix(glyphRun)
            context.textPosition = .init(
              x: 0,
              y: Double(ctLineIndex) * store.font.cellHeight - appKitFont
                .descender
            )
            let attributes =
              CTRunGetAttributes(glyphRun) as! [NSAttributedString.Key: Any]
            let attributesFont = attributes[.font] as? NSFont
            CTFontDrawGlyphs(
              attributesFont ?? appKitFont,
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
    }

    for blockLineCTLine in blockLineCTLines.reversed() {
      context.textMatrix = .init(
        translationX: 0,
        y: Double(ctLineIndex) * store.font.cellHeight - appKitFont.descender
      )
      CTLineDraw(blockLineCTLine, context)

      ctLineIndex += 1
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
  private var indent = 0
}
