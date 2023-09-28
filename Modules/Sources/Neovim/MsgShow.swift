// SPDX-License-Identifier: MIT

import Library
import Tagged

@PublicInit
public struct MsgShow: Identifiable, Sendable, Hashable {
  public var index: Int
  public var kind: Kind
  public var contentParts: [ContentPart]

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
  }

  @PublicInit
  public struct ContentPart: Sendable, Hashable {
    public var highlightID: Highlight.ID
    public var text: String
  }

  public var id: Int {
    index
  }
}
