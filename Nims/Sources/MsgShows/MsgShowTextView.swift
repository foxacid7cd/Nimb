// SPDX-License-Identifier: MIT

import AppKit
import CustomDump
import Library

public class MsgShowTextView: NSView {
  public init(store: Store) {
    self.store = store
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var contentParts = [MsgShow.ContentPart]()
  public var preferredMaxWidth: Double = 0
  public var isFirst = false
  public var isLast = false

  override public var intrinsicContentSize: NSSize {
    .init(
      width: boundingSize.width + insets.left + insets.right,
      height: boundingSize.height + insets.top + insets.bottom
    )
  }

  public func render() {
    let bigVerticalInset = max(5, store.font.cellHeight * 0.6)
    let smallVerticalInset = max(1, store.font.cellHeight * 0.15)
    let horizontalInset = max(5, store.font.cellHeight * 0.75)
    insets = .init(
      top: isFirst ? bigVerticalInset : smallVerticalInset,
      left: horizontalInset,
      bottom: isLast ? bigVerticalInset : smallVerticalInset,
      right: horizontalInset
    )

    let attributedString = NSMutableAttributedString()

    for contentPart in contentParts {
      var attributes: [NSAttributedString.Key: Any] = [
        .font: store.font.appKit(),
        .foregroundColor: store.appearance.foregroundColor(for: contentPart.highlightID).appKit,
      ]

      let backgroundColor = store.appearance.backgroundColor(for: contentPart.highlightID)
      if backgroundColor != store.appearance.defaultBackgroundColor {
        attributes[.backgroundColor] = store.appearance.backgroundColor(for: contentPart.highlightID).appKit
          .withAlphaComponent(0.6)
      }

      attributedString.append(.init(
        string: contentPart.text,
        attributes: attributes
      ))
    }

    let stringRange = CFRange(location: 0, length: attributedString.length)
    let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
    let containerSize = CGSize(width: preferredMaxWidth - (insets.left + insets.right), height: .greatestFiniteMagnitude)
    boundingSize = CTFramesetterSuggestFrameSizeWithConstraints(
      framesetter,
      stringRange,
      nil,
      containerSize,
      nil
    )
    invalidateIntrinsicContentSize()

    ctFrame = CTFramesetterCreateFrame(
      framesetter,
      stringRange,
      CGPath(
        rect: .init(
          origin: .init(x: insets.left, y: insets.bottom),
          size: .init(
            width: containerSize.width,
            height: ceil(boundingSize.height)
          )
        ),
        transform: nil
      ),
      nil
    )
    setNeedsDisplay(bounds)
  }

  override public func draw(_: NSRect) {
    guard let ctFrame else {
      return
    }

    let graphicsContext = NSGraphicsContext.current!
    let cgContext = graphicsContext.cgContext

    cgContext.saveGState()
    cgContext.translateBy(x: 0, y: store.font.appKit().descender / 2)
    CTFrameDraw(ctFrame, cgContext)
    cgContext.restoreGState()
  }

  private let store: Store
  private var boundingSize = CGSize()
  private var ctFrame: CTFrame?
  private var insets = NSEdgeInsets()
}
