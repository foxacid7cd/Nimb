// SPDX-License-Identifier: MIT

import Library

@PublicInit
public struct MsgShowsLayout: Sendable {
  public init(msgShows: [MsgShow]) {
    var items = [Item]()

    var accumulator = [[MsgShow.ContentPart]]()
    func finishTextsItem() {
      guard !accumulator.isEmpty else {
        return
      }
      items.append(.texts(accumulator))
      accumulator.removeAll(keepingCapacity: true)
    }

    for index in msgShows.indices {
      let msgShow = msgShows[index]
      let isLast = index == msgShows.index(before: msgShows.endIndex)

      if isLast, MsgShow.Kind.modal.contains(msgShow.kind) {
        finishTextsItem()
        items.append(.separator)
      }

      var text = [MsgShow.ContentPart]()
      for var contentPart in msgShow.contentParts {
        contentPart.text = contentPart.text
          .trimmingCharacters(in: .newlines)

        if !contentPart.text.isEmpty {
          text.append(contentPart)
        }
      }
      if !text.isEmpty {
        accumulator.append(text)
      }
    }
    finishTextsItem()

    self.items = items
  }

  public enum Item: Sendable {
    case texts([[MsgShow.ContentPart]])
    case separator
  }

  public var items: [Item]
}
