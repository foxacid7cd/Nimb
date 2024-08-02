// SPDX-License-Identifier: MIT

import Library
import MessagePack

@PublicInit
public struct MsgShow: Identifiable, Sendable, Hashable {
  public enum Kind: String, Sendable {
    case empty = ""
    case confirm
    case confirmSub = "confirm_sub"
    case emsg
    case echo
    case echomsg
    case echoerr
    case luaError = "lua_error"
    case rpcError = "rpc_error"
    case returnPrompt = "return_prompt"
    case quickfix
    case searchCount = "search_count"
    case wmsg

    public static let modal: Set<Kind> = [
      .confirm,
      .confirmSub,
      .returnPrompt,
      .quickfix,
    ]
  }

  @PublicInit
  public struct ContentPart: Sendable, Hashable {
    public init(raw: Value) throws {
      guard
        case let .array(raw) = raw,
        raw.count == 2,
        case let .integer(highlightID) = raw[0],
        case let .string(text) = raw[1]
      else {
        throw Failure("invalid raw content part", raw)
      }

      self.init(
        highlightID: highlightID,
        text: text
      )
    }

    public var highlightID: Highlight.ID
    public var text: String
  }

  public var index: Int
  public var kind: Kind
  public var contentParts: [ContentPart]

  public var id: Int {
    index
  }
}
