// SPDX-License-Identifier: MIT

import AppKit

class MsgShowsView: FloatingWindowView, NibLoadable {
  @IBOutlet var scrollView: NSScrollView!
  @IBOutlet var textView: NSTextView!

  override var intrinsicContentSize: NSSize {
    let boundingRect = textView.textStorage!.boundingRect(
      with: .init(
        width: 640,
        height: Double.greatestFiniteMagnitude
      ),
      options: [],
      context: NSStringDrawingContext()
    )
    return boundingRect.size
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    textView.textStorage!.setAttributedString(
      NSAttributedString(
        string: "Hello world!\nHello world!\nHello world!\nHello world!",
        attributes: [
          .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
        ]
      )
    )

    invalidateIntrinsicContentSize()
  }
}
