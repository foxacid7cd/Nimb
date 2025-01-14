// SPDX-License-Identifier: MIT

import AppKit
import CustomDump

public class CmdlineView: NSView {
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

  public init(store: Store, level: Int) {
    self.level = level
    self.store = store
    contentTextView = .init(store: store, level: level)
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
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

//  public func render() {
//    let cmdline = state.cmdlines.dictionary[level]!
//    let blockLines = state.cmdlines.blockLines[level] ?? []
//
//    if !cmdline.prompt.isEmpty {
//      promptTextField.attributedStringValue = .init(
//        string: cmdline.prompt,
//        attributes: [
//          .foregroundColor: NSColor.labelColor,
//          .font: NSFont.systemFont(ofSize: NSFont.labelFontSize),
//        ]
//      )
//
//      promptTextField.isHidden = false
//
//      promptConstraints!.content.isActive = true
//      contentConstraints!.top.isActive = false
//
//    } else {
//      promptTextField.isHidden = true
//
//      promptConstraints!.content.isActive = false
//      contentConstraints!.top.isActive = true
//    }
//
//    contentTextView.cmdline = cmdline
//    contentTextView.blockLines = blockLines
//    renderChildren(contentTextView)
//
//    let horizontalInset: Double = 14
//    let verticalInset: Double = 14
//    let smallVerticalInset: Double = 3
//    promptConstraints!.leading.constant = horizontalInset
//    promptConstraints!.trailing.constant = -horizontalInset
//    promptConstraints!.top.constant = verticalInset
//    promptConstraints!.content.constant = -smallVerticalInset
//    contentConstraints!.leading.constant = horizontalInset
//    contentConstraints!.trailing.constant = -horizontalInset
//    contentConstraints!.top.constant = verticalInset
//    contentConstraints!.bottom.constant = -verticalInset
//  }

  public func setNeedsDisplayTextView() {
    contentTextView.needsDisplay = true
  }
}
