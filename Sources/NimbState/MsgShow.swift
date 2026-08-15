// SPDX-License-Identifier: MIT

import NimbCore

@PublicInit
public struct MsgShow: Identifiable, Sendable, Hashable {
  /// Message kinds as of Neovim 0.12. Unknown kinds are treated as
  /// `unknown` per the API contract, which explicitly reserves the right to
  /// add more.
  ///
  /// Note `""` and `"empty"` are distinct: the first means the kind was not
  /// reported, the second is `:echo ""`.
  public enum Kind: String, Sendable {
    case unknown = ""
    case empty
    case confirm
    case confirmSub = "confirm_sub"
    case emsg
    case echo
    case echomsg
    case echoerr
    case completion
    case listCmd = "list_cmd"
    case luaError = "lua_error"
    case luaPrint = "lua_print"
    case progress
    case quickfix
    case returnPrompt = "return_prompt"
    case rpcError = "rpc_error"
    case searchCmd = "search_cmd"
    case searchCount = "search_count"
    case shellCmd = "shell_cmd"
    case shellErr = "shell_err"
    case shellOut = "shell_out"
    case shellRet = "shell_ret"
    case undo
    case verbose
    case wildlist
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
    public var highlightID: Highlight.ID
    public var text: String

    public init(raw: Value) throws {
      guard
        case let .array(raw) = raw,
        raw.count == 3,
        case let .integer(highlightID) = raw[2],
        case let .string(text) = raw[1]
      else {
        throw Failure("invalid raw content part", raw)
      }

      self.init(
        highlightID: highlightID,
        text: text,
      )
    }
  }

  public var index: Int
  public var kind: Kind
  public var contentParts: [ContentPart]

  /// The `id` Neovim assigned to this message, if any. A later msg_show
  /// carrying the same id replaces this message in place. Distinct from `id`
  /// below, which is this type's Identifiable conformance and is positional.
  public var messageID: Value? = nil

  public var id: Int {
    index
  }
}
