// SPDX-License-Identifier: MIT

import Library

@PublicInit
public struct MsgShowsLayout: Sendable {
  public init(_ msgShows: [MsgShow]) {
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

      accumulator.append(msgShow.contentParts)
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
