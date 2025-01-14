// SPDX-License-Identifier: MIT

import AppKit
import CustomDump

public class CmdlineTextView: NSView {
//  override public var intrinsicContentSize: NSSize {
//    guard isRendered else {
//      return .zero
//    }
//    let linesCount = max(1, blockLineCTLines.count + cmdlineCTLines.count)
//    return .init(
//      width: frame.width,
//      height: state.font.cellHeight * Double(linesCount)
//    )
//  }

  override public var frame: NSRect {
    didSet {
      if oldValue.width != frame.width {
//        render()
      }
    }
  }

  public var cmdline: Cmdline?
  public var blockLines: [[Cmdline.ContentPart]]?

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

  init(store: Store, level: Int) {
    self.store = store
    self.level = level
    super.init(frame: .init())
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

//  override public func draw(_: NSRect) {
//    guard let cmdline else {
//      return
//    }
//    let appKitFont = state.font.appKit()
//    let cursorPosition = indent + cmdline.cursorPosition
//    let context = NSGraphicsContext.current!.cgContext
//
//    var ctLineIndex = 0
//
//    for cmdlineCTLine in cmdlineCTLines.reversed() {
//      context.textMatrix = .init(
//        translationX: 0,
//        y: Double(ctLineIndex) * state.font.cellHeight - appKitFont.descender
//      )
//      CTLineDraw(cmdlineCTLine, context)
//
//      let range = CTLineGetStringRange(cmdlineCTLine)
//      if
//        state.cursorBlinkingPhase,
//        !state.isBusy,
//        cmdline.specialCharacter.isEmpty,
//        let currentCursorStyle = state.currentCursorStyle,
//        let highlightID = currentCursorStyle.attrID,
//        let cellFrame = currentCursorStyle.cellFrame(
//          columnsCount: 1,
//          font: state.font
//        ),
//        cursorPosition >= range.location,
//        cursorPosition < range.location + range.length
//      {
//        let offset = CTLineGetOffsetForStringIndex(
//          cmdlineCTLine,
//          cursorPosition,
//          nil
//        )
//        let rect = cellFrame
//          .offsetBy(
//            dx: offset,
//            dy: Double(ctLineIndex) * state.font.cellHeight
//          )
//
//        let cursorForegroundColor: Color
//        let cursorBackgroundColor: Color
//        if highlightID == Highlight.defaultID {
//          cursorForegroundColor = state.appearance.defaultBackgroundColor
//          cursorBackgroundColor = state.appearance.defaultForegroundColor
//        } else {
//          cursorForegroundColor = state.appearance
//            .foregroundColor(for: highlightID)
//          cursorBackgroundColor = state.appearance
//            .backgroundColor(for: highlightID)
//        }
//
//        context.saveGState()
//
//        context.setShouldAntialias(false)
//        context.setFillColor(cursorBackgroundColor.appKit.cgColor)
//        context.fill([rect])
//
//        if currentCursorStyle.shouldDrawParentText {
//          context.setShouldAntialias(true)
//          context.clip(to: [rect])
//          context.setFillColor(cursorForegroundColor.appKit.cgColor)
//          let glyphRuns = CTLineGetGlyphRuns(cmdlineCTLine) as! [CTRun]
//          for glyphRun in glyphRuns {
//            context.textMatrix = CTRunGetTextMatrix(glyphRun)
//            context.textPosition = .init(
//              x: 0,
//              y: Double(ctLineIndex) * state.font.cellHeight - appKitFont
//                .descender
//            )
//            let attributes =
//              CTRunGetAttributes(glyphRun) as! [NSAttributedString.Key: Any]
//            let attributesFont = attributes[.font] as? NSFont
//            CTFontDrawGlyphs(
//              attributesFont ?? appKitFont,
//              CTRunGetGlyphsPtr(glyphRun)!,
//              CTRunGetPositionsPtr(glyphRun)!,
//              CTRunGetGlyphCount(glyphRun),
//              context
//            )
//          }
//        }
//
//        context.restoreGState()
//      }
//
//      ctLineIndex += 1
//    }
//
//    for blockLineCTLine in blockLineCTLines.reversed() {
//      context.textMatrix = .init(
//        translationX: 0,
//        y: Double(ctLineIndex) * state.font.cellHeight - appKitFont.descender
//      )
//      CTLineDraw(blockLineCTLine, context)
//
//      ctLineIndex += 1
//    }
//  }

//  public func render() {
//    guard let cmdline, let blockLines else {
//      return
//    }
//    let blockLinesAttributedString = NSMutableAttributedString()
//
//    for (blockLineIndex, contentParts) in blockLines.enumerated() {
//      let lineAttributedString = NSMutableAttributedString()
//
//      for contentPart in contentParts {
//        lineAttributedString.append(.init(
//          string: contentPart.text
//            .replacingOccurrences(of: "\r", with: "↲"),
//          attributes: .init([
//            .font: state.font.appKit(),
//            .foregroundColor: NSColor.labelColor,
//          ])
//        ))
//      }
//
//      blockLinesAttributedString.append(lineAttributedString)
//
//      if blockLineIndex < blockLines.count - 1 {
//        blockLinesAttributedString.append(.init(
//          string: "\n",
//          attributes: [.font: state.font.appKit()]
//        ))
//      }
//    }
//
//    let cmdlineAttributedString = NSMutableAttributedString()
//    indent = 0
//
//    let prefix = "".padding(
//      toLength: cmdline.indent,
//      withPad: " ",
//      startingAt: 0
//    )
//    cmdlineAttributedString.append(.init(
//      string: prefix,
//      attributes: [.font: state.font.appKit()]
//    ))
//    indent += prefix.count
//
//    if !cmdline.firstCharacter.isEmpty {
//      let text = "\(cmdline.firstCharacter) "
//      cmdlineAttributedString.append(.init(
//        string: text,
//        attributes: [
//          .font: state.font.appKit(isBold: true),
//          .foregroundColor: NSColor.labelColor,
//        ]
//      ))
//      indent += text.count
//    }
//
//    let cursorPosition = indent + cmdline.cursorPosition
//
//    var location = 0
//    for contentPart in cmdline.contentParts {
//      let attributes: [NSAttributedString.Key: Any] = [
//        .font: state.font.appKit(),
//        .foregroundColor: NSColor.labelColor,
//      ]
//
//      cmdlineAttributedString.append(.init(
//        string: contentPart.text
//          .replacingOccurrences(of: "\r", with: "↲"),
//        attributes: attributes
//      ))
//      location += contentPart.text.count
//    }
//    cmdlineAttributedString.append(.init(
//      string: " ",
//      attributes: [.font: state.font.appKit()]
//    ))
//    if !cmdline.specialCharacter.isEmpty {
//      cmdlineAttributedString.insert(
//        .init(
//          string: cmdline.specialCharacter,
//          attributes: [
//            .font: state.font.appKit(),
//            .foregroundColor: NSColor.labelColor,
//          ]
//        ),
//        at: cursorPosition
//      )
//    }
//
//    let paragraphStyle = NSMutableParagraphStyle()
//    paragraphStyle.lineBreakMode = .byCharWrapping
//
//    blockLinesAttributedString.addAttribute(
//      .paragraphStyle,
//      value: paragraphStyle.copy(),
//      range: .init(location: 0, length: blockLinesAttributedString.length)
//    )
//    cmdlineAttributedString.addAttribute(
//      .paragraphStyle,
//      value: paragraphStyle.copy(),
//      range: .init(location: 0, length: cmdlineAttributedString.length)
//    )
//
//    func makeCTLines(for attributedString: NSAttributedString)
//      -> (ctFramesetter: CTFramesetter, ctFrame: CTFrame, ctLines: [CTLine])
//    {
//      let ctFramesetter =
//        CTFramesetterCreateWithAttributedString(attributedString)
//
//      let stringRange = CFRange(location: 0, length: 0)
//      let containerSize = CGSize(
//        width: bounds.width,
//        height: .greatestFiniteMagnitude
//      )
//      let boundingSize = CTFramesetterSuggestFrameSizeWithConstraints(
//        ctFramesetter,
//        stringRange,
//        nil,
//        containerSize,
//        nil
//      )
//      let path = CGPath(
//        rect: .init(
//          origin: .zero,
//          size: .init(
//            width: containerSize.width,
//            height: ceil(boundingSize.height)
//          )
//        ),
//        transform: nil
//      )
//      let ctFrame = CTFramesetterCreateFrame(
//        ctFramesetter,
//        stringRange,
//        path,
//        nil
//      )
//      return (
//        ctFramesetter,
//        ctFrame,
//        CTFrameGetLines(ctFrame) as! [CTLine]
//      )
//    }
//    self.blockLinesAttributedString = blockLinesAttributedString
//    self.cmdlineAttributedString = cmdlineAttributedString
//    (
//      blockLinesCTFramesetter,
//      blockLinesCTFrame,
//      blockLineCTLines
//    ) = makeCTLines(for: blockLinesAttributedString)
//    (
//      cmdlineCTFramesetter,
//      cmdlineCTFrame,
//      cmdlineCTLines
//    ) = makeCTLines(for: cmdlineAttributedString)
//
//    invalidateIntrinsicContentSize()
//    setNeedsDisplay(bounds)
//  }
}
