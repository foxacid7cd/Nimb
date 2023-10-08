// SPDX-License-Identifier: MIT

import CasePaths
import MessagePack

public extension API {
  func nvimGetAutocmds(opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_autocmds",
      withParameters: [
        .dictionary(opts),
      ]
    )
  }

  func nvimGetAutocmdsFast(opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_get_autocmds",
      withParameters: [
        .dictionary(opts),
      ]
    )
  }

  func nvimCreateAutocmd(event: Value, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_create_autocmd",
      withParameters: [
        event,
        .dictionary(opts),
      ]
    )
  }

  func nvimCreateAutocmdFast(event: Value, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_create_autocmd",
      withParameters: [
        event,
        .dictionary(opts),
      ]
    )
  }

  func nvimDelAutocmd(id: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_del_autocmd",
      withParameters: [
        .integer(id),
      ]
    )
  }

  func nvimDelAutocmdFast(id: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_del_autocmd",
      withParameters: [
        .integer(id),
      ]
    )
  }

  func nvimClearAutocmds(opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_clear_autocmds",
      withParameters: [
        .dictionary(opts),
      ]
    )
  }

  func nvimClearAutocmdsFast(opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_clear_autocmds",
      withParameters: [
        .dictionary(opts),
      ]
    )
  }

  func nvimCreateAugroup(name: String, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_create_augroup",
      withParameters: [
        .string(name),
        .dictionary(opts),
      ]
    )
  }

  func nvimCreateAugroupFast(name: String, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_create_augroup",
      withParameters: [
        .string(name),
        .dictionary(opts),
      ]
    )
  }

  func nvimDelAugroupByID(id: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_del_augroup_by_id",
      withParameters: [
        .integer(id),
      ]
    )
  }

  func nvimDelAugroupByIDFast(id: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_del_augroup_by_id",
      withParameters: [
        .integer(id),
      ]
    )
  }

  func nvimDelAugroupByName(name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_del_augroup_by_name",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimDelAugroupByNameFast(name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_del_augroup_by_name",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimExecAutocmds(event: Value, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_exec_autocmds",
      withParameters: [
        event,
        .dictionary(opts),
      ]
    )
  }

  func nvimExecAutocmdsFast(event: Value, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_exec_autocmds",
      withParameters: [
        event,
        .dictionary(opts),
      ]
    )
  }

  func nvimBufLineCount(bufferID: Buffer.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_line_count",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimBufLineCountFast(bufferID: Buffer.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_line_count",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimBufAttach(bufferID: Buffer.ID, sendBuffer: Bool, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_attach",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .boolean(sendBuffer),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufAttachFast(bufferID: Buffer.ID, sendBuffer: Bool, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_attach",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .boolean(sendBuffer),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufDetach(bufferID: Buffer.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_detach",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimBufDetachFast(bufferID: Buffer.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_detach",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimBufGetLines(bufferID: Buffer.ID, start: Int, end: Int, strictIndexing: Bool) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_get_lines",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(start),
        .integer(end),
        .boolean(strictIndexing),
      ]
    )
  }

  func nvimBufGetLinesFast(bufferID: Buffer.ID, start: Int, end: Int, strictIndexing: Bool) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_get_lines",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(start),
        .integer(end),
        .boolean(strictIndexing),
      ]
    )
  }

  func nvimBufSetLines(bufferID: Buffer.ID, start: Int, end: Int, strictIndexing: Bool, replacement: [Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_set_lines",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(start),
        .integer(end),
        .boolean(strictIndexing),
        .array(replacement),
      ]
    )
  }

  func nvimBufSetLinesFast(bufferID: Buffer.ID, start: Int, end: Int, strictIndexing: Bool, replacement: [Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_set_lines",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(start),
        .integer(end),
        .boolean(strictIndexing),
        .array(replacement),
      ]
    )
  }

  func nvimBufSetText(
    bufferID: Buffer.ID,
    startRow: Int,
    startCol: Int,
    endRow: Int,
    endCol: Int,
    replacement: [Value]
  ) async throws
    -> Message.Response.Result
  {
    try await rpc.call(
      method: "nvim_buf_set_text",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(startRow),
        .integer(startCol),
        .integer(endRow),
        .integer(endCol),
        .array(replacement),
      ]
    )
  }

  func nvimBufSetTextFast(
    bufferID: Buffer.ID,
    startRow: Int,
    startCol: Int,
    endRow: Int,
    endCol: Int,
    replacement: [Value]
  ) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_set_text",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(startRow),
        .integer(startCol),
        .integer(endRow),
        .integer(endCol),
        .array(replacement),
      ]
    )
  }

  func nvimBufGetText(
    bufferID: Buffer.ID,
    startRow: Int,
    startCol: Int,
    endRow: Int,
    endCol: Int,
    opts: [Value: Value]
  ) async throws
    -> Message.Response.Result
  {
    try await rpc.call(
      method: "nvim_buf_get_text",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(startRow),
        .integer(startCol),
        .integer(endRow),
        .integer(endCol),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufGetTextFast(
    bufferID: Buffer.ID,
    startRow: Int,
    startCol: Int,
    endRow: Int,
    endCol: Int,
    opts: [Value: Value]
  ) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_get_text",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(startRow),
        .integer(startCol),
        .integer(endRow),
        .integer(endCol),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufGetOffset(bufferID: Buffer.ID, index: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_get_offset",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(index),
      ]
    )
  }

  func nvimBufGetOffsetFast(bufferID: Buffer.ID, index: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_get_offset",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(index),
      ]
    )
  }

  func nvimBufGetVar(bufferID: Buffer.ID, name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_get_var",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimBufGetVarFast(bufferID: Buffer.ID, name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_get_var",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimBufGetChangedtick(bufferID: Buffer.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_get_changedtick",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimBufGetChangedtickFast(bufferID: Buffer.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_get_changedtick",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimBufGetKeymap(bufferID: Buffer.ID, mode: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_get_keymap",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(mode),
      ]
    )
  }

  func nvimBufGetKeymapFast(bufferID: Buffer.ID, mode: String) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_get_keymap",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(mode),
      ]
    )
  }

  func nvimBufSetKeymap(bufferID: Buffer.ID, mode: String, lhs: String, rhs: String, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_set_keymap",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(mode),
        .string(lhs),
        .string(rhs),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufSetKeymapFast(bufferID: Buffer.ID, mode: String, lhs: String, rhs: String, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_set_keymap",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(mode),
        .string(lhs),
        .string(rhs),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufDelKeymap(bufferID: Buffer.ID, mode: String, lhs: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_del_keymap",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(mode),
        .string(lhs),
      ]
    )
  }

  func nvimBufDelKeymapFast(bufferID: Buffer.ID, mode: String, lhs: String) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_del_keymap",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(mode),
        .string(lhs),
      ]
    )
  }

  func nvimBufSetVar(bufferID: Buffer.ID, name: String, value: Value) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_set_var",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
        value,
      ]
    )
  }

  func nvimBufSetVarFast(bufferID: Buffer.ID, name: String, value: Value) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_set_var",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
        value,
      ]
    )
  }

  func nvimBufDelVar(bufferID: Buffer.ID, name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_del_var",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimBufDelVarFast(bufferID: Buffer.ID, name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_del_var",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimBufGetName(bufferID: Buffer.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_get_name",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimBufGetNameFast(bufferID: Buffer.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_get_name",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimBufSetName(bufferID: Buffer.ID, name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_set_name",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimBufSetNameFast(bufferID: Buffer.ID, name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_set_name",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimBufIsLoaded(bufferID: Buffer.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_is_loaded",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimBufIsLoadedFast(bufferID: Buffer.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_is_loaded",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimBufDelete(bufferID: Buffer.ID, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_delete",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufDeleteFast(bufferID: Buffer.ID, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_delete",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufIsValid(bufferID: Buffer.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_is_valid",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimBufIsValidFast(bufferID: Buffer.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_is_valid",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimBufDelMark(bufferID: Buffer.ID, name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_del_mark",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimBufDelMarkFast(bufferID: Buffer.ID, name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_del_mark",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimBufSetMark(bufferID: Buffer.ID, name: String, line: Int, col: Int, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_set_mark",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
        .integer(line),
        .integer(col),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufSetMarkFast(bufferID: Buffer.ID, name: String, line: Int, col: Int, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_set_mark",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
        .integer(line),
        .integer(col),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufGetMark(bufferID: Buffer.ID, name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_get_mark",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimBufGetMarkFast(bufferID: Buffer.ID, name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_get_mark",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimBufCall(bufferID: Buffer.ID, fun: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_call",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(fun),
      ]
    )
  }

  func nvimBufCallFast(bufferID: Buffer.ID, fun: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_call",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(fun),
      ]
    )
  }

  func nvimParseCmd(str: String, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_parse_cmd",
      withParameters: [
        .string(str),
        .dictionary(opts),
      ]
    )
  }

  func nvimParseCmdFast(str: String, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_parse_cmd",
      withParameters: [
        .string(str),
        .dictionary(opts),
      ]
    )
  }

  func nvimCmd(cmd: [Value: Value], opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_cmd",
      withParameters: [
        .dictionary(cmd),
        .dictionary(opts),
      ]
    )
  }

  func nvimCmdFast(cmd: [Value: Value], opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_cmd",
      withParameters: [
        .dictionary(cmd),
        .dictionary(opts),
      ]
    )
  }

  func nvimCreateUserCommand(name: String, command: Value, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_create_user_command",
      withParameters: [
        .string(name),
        command,
        .dictionary(opts),
      ]
    )
  }

  func nvimCreateUserCommandFast(name: String, command: Value, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_create_user_command",
      withParameters: [
        .string(name),
        command,
        .dictionary(opts),
      ]
    )
  }

  func nvimDelUserCommand(name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_del_user_command",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimDelUserCommandFast(name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_del_user_command",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimBufCreateUserCommand(bufferID: Buffer.ID, name: String, command: Value, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_create_user_command",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
        command,
        .dictionary(opts),
      ]
    )
  }

  func nvimBufCreateUserCommandFast(bufferID: Buffer.ID, name: String, command: Value, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_create_user_command",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
        command,
        .dictionary(opts),
      ]
    )
  }

  func nvimBufDelUserCommand(bufferID: Buffer.ID, name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_del_user_command",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimBufDelUserCommandFast(bufferID: Buffer.ID, name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_del_user_command",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimGetCommands(opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_commands",
      withParameters: [
        .dictionary(opts),
      ]
    )
  }

  func nvimGetCommandsFast(opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_get_commands",
      withParameters: [
        .dictionary(opts),
      ]
    )
  }

  func nvimBufGetCommands(bufferID: Buffer.ID, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_get_commands",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufGetCommandsFast(bufferID: Buffer.ID, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_get_commands",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .dictionary(opts),
      ]
    )
  }

  func nvimGetOptionInfo(name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_option_info",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimGetOptionInfoFast(name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_get_option_info",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimCreateNamespace(name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_create_namespace",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimCreateNamespaceFast(name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_create_namespace",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimGetNamespaces() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_namespaces",
      withParameters: [
      ]
    )
  }

  func nvimGetNamespacesFast() async throws {
    try await rpc.fastCall(
      method: "nvim_get_namespaces",
      withParameters: [
      ]
    )
  }

  func nvimBufGetExtmarkByID(bufferID: Buffer.ID, nsID: Int, id: Int, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_get_extmark_by_id",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(nsID),
        .integer(id),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufGetExtmarkByIDFast(bufferID: Buffer.ID, nsID: Int, id: Int, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_get_extmark_by_id",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(nsID),
        .integer(id),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufGetExtmarks(bufferID: Buffer.ID, nsID: Int, start: Value, end: Value, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_get_extmarks",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(nsID),
        start,
        end,
        .dictionary(opts),
      ]
    )
  }

  func nvimBufGetExtmarksFast(bufferID: Buffer.ID, nsID: Int, start: Value, end: Value, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_get_extmarks",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(nsID),
        start,
        end,
        .dictionary(opts),
      ]
    )
  }

  func nvimBufSetExtmark(bufferID: Buffer.ID, nsID: Int, line: Int, col: Int, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_set_extmark",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(nsID),
        .integer(line),
        .integer(col),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufSetExtmarkFast(bufferID: Buffer.ID, nsID: Int, line: Int, col: Int, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_set_extmark",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(nsID),
        .integer(line),
        .integer(col),
        .dictionary(opts),
      ]
    )
  }

  func nvimBufDelExtmark(bufferID: Buffer.ID, nsID: Int, id: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_del_extmark",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(nsID),
        .integer(id),
      ]
    )
  }

  func nvimBufDelExtmarkFast(bufferID: Buffer.ID, nsID: Int, id: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_del_extmark",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(nsID),
        .integer(id),
      ]
    )
  }

  func nvimBufAddHighlight(bufferID: Buffer.ID, nsID: Int, hlGroup: String, line: Int, colStart: Int, colEnd: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_add_highlight",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(nsID),
        .string(hlGroup),
        .integer(line),
        .integer(colStart),
        .integer(colEnd),
      ]
    )
  }

  func nvimBufAddHighlightFast(bufferID: Buffer.ID, nsID: Int, hlGroup: String, line: Int, colStart: Int, colEnd: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_add_highlight",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(nsID),
        .string(hlGroup),
        .integer(line),
        .integer(colStart),
        .integer(colEnd),
      ]
    )
  }

  func nvimBufClearNamespace(bufferID: Buffer.ID, nsID: Int, lineStart: Int, lineEnd: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_clear_namespace",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(nsID),
        .integer(lineStart),
        .integer(lineEnd),
      ]
    )
  }

  func nvimBufClearNamespaceFast(bufferID: Buffer.ID, nsID: Int, lineStart: Int, lineEnd: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_clear_namespace",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .integer(nsID),
        .integer(lineStart),
        .integer(lineEnd),
      ]
    )
  }

  func nvimSetDecorationProvider(nsID: Int, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_decoration_provider",
      withParameters: [
        .integer(nsID),
        .dictionary(opts),
      ]
    )
  }

  func nvimSetDecorationProviderFast(nsID: Int, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_set_decoration_provider",
      withParameters: [
        .integer(nsID),
        .dictionary(opts),
      ]
    )
  }

  func nvimGetOptionValue(name: String, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_option_value",
      withParameters: [
        .string(name),
        .dictionary(opts),
      ]
    )
  }

  func nvimGetOptionValueFast(name: String, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_get_option_value",
      withParameters: [
        .string(name),
        .dictionary(opts),
      ]
    )
  }

  func nvimSetOptionValue(name: String, value: Value, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_option_value",
      withParameters: [
        .string(name),
        value,
        .dictionary(opts),
      ]
    )
  }

  func nvimSetOptionValueFast(name: String, value: Value, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_set_option_value",
      withParameters: [
        .string(name),
        value,
        .dictionary(opts),
      ]
    )
  }

  func nvimGetAllOptionsInfo() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_all_options_info",
      withParameters: [
      ]
    )
  }

  func nvimGetAllOptionsInfoFast() async throws {
    try await rpc.fastCall(
      method: "nvim_get_all_options_info",
      withParameters: [
      ]
    )
  }

  func nvimGetOptionInfo2(name: String, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_option_info2",
      withParameters: [
        .string(name),
        .dictionary(opts),
      ]
    )
  }

  func nvimGetOptionInfo2Fast(name: String, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_get_option_info2",
      withParameters: [
        .string(name),
        .dictionary(opts),
      ]
    )
  }

  func nvimSetOption(name: String, value: Value) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_option",
      withParameters: [
        .string(name),
        value,
      ]
    )
  }

  func nvimSetOptionFast(name: String, value: Value) async throws {
    try await rpc.fastCall(
      method: "nvim_set_option",
      withParameters: [
        .string(name),
        value,
      ]
    )
  }

  func nvimGetOption(name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_option",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimGetOptionFast(name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_get_option",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimBufGetOption(bufferID: Buffer.ID, name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_get_option",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimBufGetOptionFast(bufferID: Buffer.ID, name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_get_option",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
      ]
    )
  }

  func nvimBufSetOption(bufferID: Buffer.ID, name: String, value: Value) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_buf_set_option",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
        value,
      ]
    )
  }

  func nvimBufSetOptionFast(bufferID: Buffer.ID, name: String, value: Value) async throws {
    try await rpc.fastCall(
      method: "nvim_buf_set_option",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .string(name),
        value,
      ]
    )
  }

  func nvimWinGetOption(windowID: Window.ID, name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_get_option",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .string(name),
      ]
    )
  }

  func nvimWinGetOptionFast(windowID: Window.ID, name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_win_get_option",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .string(name),
      ]
    )
  }

  func nvimWinSetOption(windowID: Window.ID, name: String, value: Value) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_set_option",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .string(name),
        value,
      ]
    )
  }

  func nvimWinSetOptionFast(windowID: Window.ID, name: String, value: Value) async throws {
    try await rpc.fastCall(
      method: "nvim_win_set_option",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .string(name),
        value,
      ]
    )
  }

  func nvimTabpageListWins(tabpageID: Tabpage.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_tabpage_list_wins",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
      ]
    )
  }

  func nvimTabpageListWinsFast(tabpageID: Tabpage.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_tabpage_list_wins",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
      ]
    )
  }

  func nvimTabpageGetVar(tabpageID: Tabpage.ID, name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_tabpage_get_var",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
        .string(name),
      ]
    )
  }

  func nvimTabpageGetVarFast(tabpageID: Tabpage.ID, name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_tabpage_get_var",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
        .string(name),
      ]
    )
  }

  func nvimTabpageSetVar(tabpageID: Tabpage.ID, name: String, value: Value) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_tabpage_set_var",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
        .string(name),
        value,
      ]
    )
  }

  func nvimTabpageSetVarFast(tabpageID: Tabpage.ID, name: String, value: Value) async throws {
    try await rpc.fastCall(
      method: "nvim_tabpage_set_var",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
        .string(name),
        value,
      ]
    )
  }

  func nvimTabpageDelVar(tabpageID: Tabpage.ID, name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_tabpage_del_var",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
        .string(name),
      ]
    )
  }

  func nvimTabpageDelVarFast(tabpageID: Tabpage.ID, name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_tabpage_del_var",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
        .string(name),
      ]
    )
  }

  func nvimTabpageGetWin(tabpageID: Tabpage.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_tabpage_get_win",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
      ]
    )
  }

  func nvimTabpageGetWinFast(tabpageID: Tabpage.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_tabpage_get_win",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
      ]
    )
  }

  func nvimTabpageGetNumber(tabpageID: Tabpage.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_tabpage_get_number",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
      ]
    )
  }

  func nvimTabpageGetNumberFast(tabpageID: Tabpage.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_tabpage_get_number",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
      ]
    )
  }

  func nvimTabpageIsValid(tabpageID: Tabpage.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_tabpage_is_valid",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
      ]
    )
  }

  func nvimTabpageIsValidFast(tabpageID: Tabpage.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_tabpage_is_valid",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
      ]
    )
  }

  func nvimUIAttach(width: Int, height: Int, options: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_ui_attach",
      withParameters: [
        .integer(width),
        .integer(height),
        .dictionary(options),
      ]
    )
  }

  func nvimUIAttachFast(width: Int, height: Int, options: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_ui_attach",
      withParameters: [
        .integer(width),
        .integer(height),
        .dictionary(options),
      ]
    )
  }

  func nvimUISetFocus(gained: Bool) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_ui_set_focus",
      withParameters: [
        .boolean(gained),
      ]
    )
  }

  func nvimUISetFocusFast(gained: Bool) async throws {
    try await rpc.fastCall(
      method: "nvim_ui_set_focus",
      withParameters: [
        .boolean(gained),
      ]
    )
  }

  func nvimUIDetach() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_ui_detach",
      withParameters: [
      ]
    )
  }

  func nvimUIDetachFast() async throws {
    try await rpc.fastCall(
      method: "nvim_ui_detach",
      withParameters: [
      ]
    )
  }

  func nvimUITryResize(width: Int, height: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_ui_try_resize",
      withParameters: [
        .integer(width),
        .integer(height),
      ]
    )
  }

  func nvimUITryResizeFast(width: Int, height: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_ui_try_resize",
      withParameters: [
        .integer(width),
        .integer(height),
      ]
    )
  }

  func nvimUISetOption(name: String, value: Value) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_ui_set_option",
      withParameters: [
        .string(name),
        value,
      ]
    )
  }

  func nvimUISetOptionFast(name: String, value: Value) async throws {
    try await rpc.fastCall(
      method: "nvim_ui_set_option",
      withParameters: [
        .string(name),
        value,
      ]
    )
  }

  func nvimUITryResizeGrid(grid: Int, width: Int, height: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_ui_try_resize_grid",
      withParameters: [
        .integer(grid),
        .integer(width),
        .integer(height),
      ]
    )
  }

  func nvimUITryResizeGridFast(grid: Int, width: Int, height: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_ui_try_resize_grid",
      withParameters: [
        .integer(grid),
        .integer(width),
        .integer(height),
      ]
    )
  }

  func nvimUIPumSetHeight(height: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_ui_pum_set_height",
      withParameters: [
        .integer(height),
      ]
    )
  }

  func nvimUIPumSetHeightFast(height: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_ui_pum_set_height",
      withParameters: [
        .integer(height),
      ]
    )
  }

  func nvimUIPumSetBounds(width: Double, height: Double, row: Double, col: Double) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_ui_pum_set_bounds",
      withParameters: [
        .float(width),
        .float(height),
        .float(row),
        .float(col),
      ]
    )
  }

  func nvimUIPumSetBoundsFast(width: Double, height: Double, row: Double, col: Double) async throws {
    try await rpc.fastCall(
      method: "nvim_ui_pum_set_bounds",
      withParameters: [
        .float(width),
        .float(height),
        .float(row),
        .float(col),
      ]
    )
  }

  func nvimGetHlIDByName(name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_hl_id_by_name",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimGetHlIDByNameFast(name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_get_hl_id_by_name",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimGetHl(nsID: Int, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_hl",
      withParameters: [
        .integer(nsID),
        .dictionary(opts),
      ]
    )
  }

  func nvimGetHlFast(nsID: Int, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_get_hl",
      withParameters: [
        .integer(nsID),
        .dictionary(opts),
      ]
    )
  }

  func nvimSetHl(nsID: Int, name: String, val: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_hl",
      withParameters: [
        .integer(nsID),
        .string(name),
        .dictionary(val),
      ]
    )
  }

  func nvimSetHlFast(nsID: Int, name: String, val: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_set_hl",
      withParameters: [
        .integer(nsID),
        .string(name),
        .dictionary(val),
      ]
    )
  }

  func nvimSetHlNs(nsID: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_hl_ns",
      withParameters: [
        .integer(nsID),
      ]
    )
  }

  func nvimSetHlNsFast(nsID: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_set_hl_ns",
      withParameters: [
        .integer(nsID),
      ]
    )
  }

  func nvimSetHlNsFast(nsID: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_hl_ns_fast",
      withParameters: [
        .integer(nsID),
      ]
    )
  }

  func nvimSetHlNsFastFast(nsID: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_set_hl_ns_fast",
      withParameters: [
        .integer(nsID),
      ]
    )
  }

  func nvimFeedkeys(keys: String, mode: String, escapeKs: Bool) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_feedkeys",
      withParameters: [
        .string(keys),
        .string(mode),
        .boolean(escapeKs),
      ]
    )
  }

  func nvimFeedkeysFast(keys: String, mode: String, escapeKs: Bool) async throws {
    try await rpc.fastCall(
      method: "nvim_feedkeys",
      withParameters: [
        .string(keys),
        .string(mode),
        .boolean(escapeKs),
      ]
    )
  }

  func nvimInput(keys: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_input",
      withParameters: [
        .string(keys),
      ]
    )
  }

  func nvimInputFast(keys: String) async throws {
    try await rpc.fastCall(
      method: "nvim_input",
      withParameters: [
        .string(keys),
      ]
    )
  }

  func nvimInputMouse(button: String, action: String, modifier: String, grid: Int, row: Int, col: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_input_mouse",
      withParameters: [
        .string(button),
        .string(action),
        .string(modifier),
        .integer(grid),
        .integer(row),
        .integer(col),
      ]
    )
  }

  func nvimInputMouseFast(button: String, action: String, modifier: String, grid: Int, row: Int, col: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_input_mouse",
      withParameters: [
        .string(button),
        .string(action),
        .string(modifier),
        .integer(grid),
        .integer(row),
        .integer(col),
      ]
    )
  }

  func nvimReplaceTermcodes(str: String, fromPart: Bool, doLt: Bool, special: Bool) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_replace_termcodes",
      withParameters: [
        .string(str),
        .boolean(fromPart),
        .boolean(doLt),
        .boolean(special),
      ]
    )
  }

  func nvimReplaceTermcodesFast(str: String, fromPart: Bool, doLt: Bool, special: Bool) async throws {
    try await rpc.fastCall(
      method: "nvim_replace_termcodes",
      withParameters: [
        .string(str),
        .boolean(fromPart),
        .boolean(doLt),
        .boolean(special),
      ]
    )
  }

  func nvimExecLua(code: String, args: [Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_exec_lua",
      withParameters: [
        .string(code),
        .array(args),
      ]
    )
  }

  func nvimExecLuaFast(code: String, args: [Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_exec_lua",
      withParameters: [
        .string(code),
        .array(args),
      ]
    )
  }

  func nvimNotify(msg: String, logLevel: Int, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_notify",
      withParameters: [
        .string(msg),
        .integer(logLevel),
        .dictionary(opts),
      ]
    )
  }

  func nvimNotifyFast(msg: String, logLevel: Int, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_notify",
      withParameters: [
        .string(msg),
        .integer(logLevel),
        .dictionary(opts),
      ]
    )
  }

  func nvimStrwidth(text: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_strwidth",
      withParameters: [
        .string(text),
      ]
    )
  }

  func nvimStrwidthFast(text: String) async throws {
    try await rpc.fastCall(
      method: "nvim_strwidth",
      withParameters: [
        .string(text),
      ]
    )
  }

  func nvimListRuntimePaths() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_list_runtime_paths",
      withParameters: [
      ]
    )
  }

  func nvimListRuntimePathsFast() async throws {
    try await rpc.fastCall(
      method: "nvim_list_runtime_paths",
      withParameters: [
      ]
    )
  }

  func nvimGetRuntimeFile(name: String, all: Bool) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_runtime_file",
      withParameters: [
        .string(name),
        .boolean(all),
      ]
    )
  }

  func nvimGetRuntimeFileFast(name: String, all: Bool) async throws {
    try await rpc.fastCall(
      method: "nvim_get_runtime_file",
      withParameters: [
        .string(name),
        .boolean(all),
      ]
    )
  }

  func nvimSetCurrentDir(dir: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_current_dir",
      withParameters: [
        .string(dir),
      ]
    )
  }

  func nvimSetCurrentDirFast(dir: String) async throws {
    try await rpc.fastCall(
      method: "nvim_set_current_dir",
      withParameters: [
        .string(dir),
      ]
    )
  }

  func nvimGetCurrentLine() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_current_line",
      withParameters: [
      ]
    )
  }

  func nvimGetCurrentLineFast() async throws {
    try await rpc.fastCall(
      method: "nvim_get_current_line",
      withParameters: [
      ]
    )
  }

  func nvimSetCurrentLine(line: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_current_line",
      withParameters: [
        .string(line),
      ]
    )
  }

  func nvimSetCurrentLineFast(line: String) async throws {
    try await rpc.fastCall(
      method: "nvim_set_current_line",
      withParameters: [
        .string(line),
      ]
    )
  }

  func nvimDelCurrentLine() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_del_current_line",
      withParameters: [
      ]
    )
  }

  func nvimDelCurrentLineFast() async throws {
    try await rpc.fastCall(
      method: "nvim_del_current_line",
      withParameters: [
      ]
    )
  }

  func nvimGetVar(name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_var",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimGetVarFast(name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_get_var",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimSetVar(name: String, value: Value) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_var",
      withParameters: [
        .string(name),
        value,
      ]
    )
  }

  func nvimSetVarFast(name: String, value: Value) async throws {
    try await rpc.fastCall(
      method: "nvim_set_var",
      withParameters: [
        .string(name),
        value,
      ]
    )
  }

  func nvimDelVar(name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_del_var",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimDelVarFast(name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_del_var",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimGetVvar(name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_vvar",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimGetVvarFast(name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_get_vvar",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimSetVvar(name: String, value: Value) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_vvar",
      withParameters: [
        .string(name),
        value,
      ]
    )
  }

  func nvimSetVvarFast(name: String, value: Value) async throws {
    try await rpc.fastCall(
      method: "nvim_set_vvar",
      withParameters: [
        .string(name),
        value,
      ]
    )
  }

  func nvimEcho(chunks: [Value], history: Bool, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_echo",
      withParameters: [
        .array(chunks),
        .boolean(history),
        .dictionary(opts),
      ]
    )
  }

  func nvimEchoFast(chunks: [Value], history: Bool, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_echo",
      withParameters: [
        .array(chunks),
        .boolean(history),
        .dictionary(opts),
      ]
    )
  }

  func nvimOutWrite(str: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_out_write",
      withParameters: [
        .string(str),
      ]
    )
  }

  func nvimOutWriteFast(str: String) async throws {
    try await rpc.fastCall(
      method: "nvim_out_write",
      withParameters: [
        .string(str),
      ]
    )
  }

  func nvimErrWrite(str: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_err_write",
      withParameters: [
        .string(str),
      ]
    )
  }

  func nvimErrWriteFast(str: String) async throws {
    try await rpc.fastCall(
      method: "nvim_err_write",
      withParameters: [
        .string(str),
      ]
    )
  }

  func nvimErrWriteln(str: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_err_writeln",
      withParameters: [
        .string(str),
      ]
    )
  }

  func nvimErrWritelnFast(str: String) async throws {
    try await rpc.fastCall(
      method: "nvim_err_writeln",
      withParameters: [
        .string(str),
      ]
    )
  }

  func nvimListBufs() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_list_bufs",
      withParameters: [
      ]
    )
  }

  func nvimListBufsFast() async throws {
    try await rpc.fastCall(
      method: "nvim_list_bufs",
      withParameters: [
      ]
    )
  }

  func nvimGetCurrentBuf() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_current_buf",
      withParameters: [
      ]
    )
  }

  func nvimGetCurrentBufFast() async throws {
    try await rpc.fastCall(
      method: "nvim_get_current_buf",
      withParameters: [
      ]
    )
  }

  func nvimSetCurrentBuf(bufferID: Buffer.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_current_buf",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimSetCurrentBufFast(bufferID: Buffer.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_set_current_buf",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimListWins() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_list_wins",
      withParameters: [
      ]
    )
  }

  func nvimListWinsFast() async throws {
    try await rpc.fastCall(
      method: "nvim_list_wins",
      withParameters: [
      ]
    )
  }

  func nvimGetCurrentWin() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_current_win",
      withParameters: [
      ]
    )
  }

  func nvimGetCurrentWinFast() async throws {
    try await rpc.fastCall(
      method: "nvim_get_current_win",
      withParameters: [
      ]
    )
  }

  func nvimSetCurrentWin(windowID: Window.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_current_win",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimSetCurrentWinFast(windowID: Window.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_set_current_win",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimCreateBuf(listed: Bool, scratch: Bool) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_create_buf",
      withParameters: [
        .boolean(listed),
        .boolean(scratch),
      ]
    )
  }

  func nvimCreateBufFast(listed: Bool, scratch: Bool) async throws {
    try await rpc.fastCall(
      method: "nvim_create_buf",
      withParameters: [
        .boolean(listed),
        .boolean(scratch),
      ]
    )
  }

  func nvimOpenTerm(bufferID: Buffer.ID, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_open_term",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .dictionary(opts),
      ]
    )
  }

  func nvimOpenTermFast(bufferID: Buffer.ID, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_open_term",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .dictionary(opts),
      ]
    )
  }

  func nvimChanSend(chan: Int, data: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_chan_send",
      withParameters: [
        .integer(chan),
        .string(data),
      ]
    )
  }

  func nvimChanSendFast(chan: Int, data: String) async throws {
    try await rpc.fastCall(
      method: "nvim_chan_send",
      withParameters: [
        .integer(chan),
        .string(data),
      ]
    )
  }

  func nvimListTabpages() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_list_tabpages",
      withParameters: [
      ]
    )
  }

  func nvimListTabpagesFast() async throws {
    try await rpc.fastCall(
      method: "nvim_list_tabpages",
      withParameters: [
      ]
    )
  }

  func nvimGetCurrentTabpage() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_current_tabpage",
      withParameters: [
      ]
    )
  }

  func nvimGetCurrentTabpageFast() async throws {
    try await rpc.fastCall(
      method: "nvim_get_current_tabpage",
      withParameters: [
      ]
    )
  }

  func nvimSetCurrentTabpage(tabpageID: Tabpage.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_current_tabpage",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
      ]
    )
  }

  func nvimSetCurrentTabpageFast(tabpageID: Tabpage.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_set_current_tabpage",
      withParameters: [
        .ext(type: References.Tabpage.type, data: tabpageID.data),
      ]
    )
  }

  func nvimPaste(data: String, crlf: Bool, phase: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_paste",
      withParameters: [
        .string(data),
        .boolean(crlf),
        .integer(phase),
      ]
    )
  }

  func nvimPasteFast(data: String, crlf: Bool, phase: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_paste",
      withParameters: [
        .string(data),
        .boolean(crlf),
        .integer(phase),
      ]
    )
  }

  func nvimPut(lines: [Value], type: String, after: Bool, follow: Bool) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_put",
      withParameters: [
        .array(lines),
        .string(type),
        .boolean(after),
        .boolean(follow),
      ]
    )
  }

  func nvimPutFast(lines: [Value], type: String, after: Bool, follow: Bool) async throws {
    try await rpc.fastCall(
      method: "nvim_put",
      withParameters: [
        .array(lines),
        .string(type),
        .boolean(after),
        .boolean(follow),
      ]
    )
  }

  func nvimSubscribe(event: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_subscribe",
      withParameters: [
        .string(event),
      ]
    )
  }

  func nvimSubscribeFast(event: String) async throws {
    try await rpc.fastCall(
      method: "nvim_subscribe",
      withParameters: [
        .string(event),
      ]
    )
  }

  func nvimUnsubscribe(event: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_unsubscribe",
      withParameters: [
        .string(event),
      ]
    )
  }

  func nvimUnsubscribeFast(event: String) async throws {
    try await rpc.fastCall(
      method: "nvim_unsubscribe",
      withParameters: [
        .string(event),
      ]
    )
  }

  func nvimGetColorByName(name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_color_by_name",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimGetColorByNameFast(name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_get_color_by_name",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimGetColorMap() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_color_map",
      withParameters: [
      ]
    )
  }

  func nvimGetColorMapFast() async throws {
    try await rpc.fastCall(
      method: "nvim_get_color_map",
      withParameters: [
      ]
    )
  }

  func nvimGetContext(opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_context",
      withParameters: [
        .dictionary(opts),
      ]
    )
  }

  func nvimGetContextFast(opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_get_context",
      withParameters: [
        .dictionary(opts),
      ]
    )
  }

  func nvimLoadContext(dict: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_load_context",
      withParameters: [
        .dictionary(dict),
      ]
    )
  }

  func nvimLoadContextFast(dict: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_load_context",
      withParameters: [
        .dictionary(dict),
      ]
    )
  }

  func nvimGetMode() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_mode",
      withParameters: [
      ]
    )
  }

  func nvimGetModeFast() async throws {
    try await rpc.fastCall(
      method: "nvim_get_mode",
      withParameters: [
      ]
    )
  }

  func nvimGetKeymap(mode: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_keymap",
      withParameters: [
        .string(mode),
      ]
    )
  }

  func nvimGetKeymapFast(mode: String) async throws {
    try await rpc.fastCall(
      method: "nvim_get_keymap",
      withParameters: [
        .string(mode),
      ]
    )
  }

  func nvimSetKeymap(mode: String, lhs: String, rhs: String, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_set_keymap",
      withParameters: [
        .string(mode),
        .string(lhs),
        .string(rhs),
        .dictionary(opts),
      ]
    )
  }

  func nvimSetKeymapFast(mode: String, lhs: String, rhs: String, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_set_keymap",
      withParameters: [
        .string(mode),
        .string(lhs),
        .string(rhs),
        .dictionary(opts),
      ]
    )
  }

  func nvimDelKeymap(mode: String, lhs: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_del_keymap",
      withParameters: [
        .string(mode),
        .string(lhs),
      ]
    )
  }

  func nvimDelKeymapFast(mode: String, lhs: String) async throws {
    try await rpc.fastCall(
      method: "nvim_del_keymap",
      withParameters: [
        .string(mode),
        .string(lhs),
      ]
    )
  }

  func nvimGetApiInfo() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_api_info",
      withParameters: [
      ]
    )
  }

  func nvimGetApiInfoFast() async throws {
    try await rpc.fastCall(
      method: "nvim_get_api_info",
      withParameters: [
      ]
    )
  }

  func nvimSetClientInfo(
    name: String,
    version: [Value: Value],
    type: String,
    methods: [Value: Value],
    attributes: [Value: Value]
  ) async throws
    -> Message.Response.Result
  {
    try await rpc.call(
      method: "nvim_set_client_info",
      withParameters: [
        .string(name),
        .dictionary(version),
        .string(type),
        .dictionary(methods),
        .dictionary(attributes),
      ]
    )
  }

  func nvimSetClientInfoFast(
    name: String,
    version: [Value: Value],
    type: String,
    methods: [Value: Value],
    attributes: [Value: Value]
  ) async throws {
    try await rpc.fastCall(
      method: "nvim_set_client_info",
      withParameters: [
        .string(name),
        .dictionary(version),
        .string(type),
        .dictionary(methods),
        .dictionary(attributes),
      ]
    )
  }

  func nvimGetChanInfo(chan: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_chan_info",
      withParameters: [
        .integer(chan),
      ]
    )
  }

  func nvimGetChanInfoFast(chan: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_get_chan_info",
      withParameters: [
        .integer(chan),
      ]
    )
  }

  func nvimListChans() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_list_chans",
      withParameters: [
      ]
    )
  }

  func nvimListChansFast() async throws {
    try await rpc.fastCall(
      method: "nvim_list_chans",
      withParameters: [
      ]
    )
  }

  func nvimCallAtomic(calls: [Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_call_atomic",
      withParameters: [
        .array(calls),
      ]
    )
  }

  func nvimCallAtomicFast(calls: [Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_call_atomic",
      withParameters: [
        .array(calls),
      ]
    )
  }

  func nvimListUIs() async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_list_uis",
      withParameters: [
      ]
    )
  }

  func nvimListUIsFast() async throws {
    try await rpc.fastCall(
      method: "nvim_list_uis",
      withParameters: [
      ]
    )
  }

  func nvimGetProcChildren(pid: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_proc_children",
      withParameters: [
        .integer(pid),
      ]
    )
  }

  func nvimGetProcChildrenFast(pid: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_get_proc_children",
      withParameters: [
        .integer(pid),
      ]
    )
  }

  func nvimGetProc(pid: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_proc",
      withParameters: [
        .integer(pid),
      ]
    )
  }

  func nvimGetProcFast(pid: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_get_proc",
      withParameters: [
        .integer(pid),
      ]
    )
  }

  func nvimSelectPopupmenuItem(item: Int, insert: Bool, finish: Bool, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_select_popupmenu_item",
      withParameters: [
        .integer(item),
        .boolean(insert),
        .boolean(finish),
        .dictionary(opts),
      ]
    )
  }

  func nvimSelectPopupmenuItemFast(item: Int, insert: Bool, finish: Bool, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_select_popupmenu_item",
      withParameters: [
        .integer(item),
        .boolean(insert),
        .boolean(finish),
        .dictionary(opts),
      ]
    )
  }

  func nvimDelMark(name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_del_mark",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimDelMarkFast(name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_del_mark",
      withParameters: [
        .string(name),
      ]
    )
  }

  func nvimGetMark(name: String, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_get_mark",
      withParameters: [
        .string(name),
        .dictionary(opts),
      ]
    )
  }

  func nvimGetMarkFast(name: String, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_get_mark",
      withParameters: [
        .string(name),
        .dictionary(opts),
      ]
    )
  }

  func nvimEvalStatusline(str: String, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_eval_statusline",
      withParameters: [
        .string(str),
        .dictionary(opts),
      ]
    )
  }

  func nvimEvalStatuslineFast(str: String, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_eval_statusline",
      withParameters: [
        .string(str),
        .dictionary(opts),
      ]
    )
  }

  func nvimExec2(src: String, opts: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_exec2",
      withParameters: [
        .string(src),
        .dictionary(opts),
      ]
    )
  }

  func nvimExec2Fast(src: String, opts: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_exec2",
      withParameters: [
        .string(src),
        .dictionary(opts),
      ]
    )
  }

  func nvimCommand(command: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_command",
      withParameters: [
        .string(command),
      ]
    )
  }

  func nvimCommandFast(command: String) async throws {
    try await rpc.fastCall(
      method: "nvim_command",
      withParameters: [
        .string(command),
      ]
    )
  }

  func nvimEval(expr: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_eval",
      withParameters: [
        .string(expr),
      ]
    )
  }

  func nvimEvalFast(expr: String) async throws {
    try await rpc.fastCall(
      method: "nvim_eval",
      withParameters: [
        .string(expr),
      ]
    )
  }

  func nvimCallFunction(fn: String, args: [Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_call_function",
      withParameters: [
        .string(fn),
        .array(args),
      ]
    )
  }

  func nvimCallFunctionFast(fn: String, args: [Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_call_function",
      withParameters: [
        .string(fn),
        .array(args),
      ]
    )
  }

  func nvimCallDictFunction(dict: Value, fn: String, args: [Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_call_dict_function",
      withParameters: [
        dict,
        .string(fn),
        .array(args),
      ]
    )
  }

  func nvimCallDictFunctionFast(dict: Value, fn: String, args: [Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_call_dict_function",
      withParameters: [
        dict,
        .string(fn),
        .array(args),
      ]
    )
  }

  func nvimParseExpression(expr: String, flags: String, highlight: Bool) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_parse_expression",
      withParameters: [
        .string(expr),
        .string(flags),
        .boolean(highlight),
      ]
    )
  }

  func nvimParseExpressionFast(expr: String, flags: String, highlight: Bool) async throws {
    try await rpc.fastCall(
      method: "nvim_parse_expression",
      withParameters: [
        .string(expr),
        .string(flags),
        .boolean(highlight),
      ]
    )
  }

  func nvimOpenWin(bufferID: Buffer.ID, enter: Bool, config: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_open_win",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .boolean(enter),
        .dictionary(config),
      ]
    )
  }

  func nvimOpenWinFast(bufferID: Buffer.ID, enter: Bool, config: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_open_win",
      withParameters: [
        .ext(type: References.Buffer.type, data: bufferID.data),
        .boolean(enter),
        .dictionary(config),
      ]
    )
  }

  func nvimWinSetConfig(windowID: Window.ID, config: [Value: Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_set_config",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .dictionary(config),
      ]
    )
  }

  func nvimWinSetConfigFast(windowID: Window.ID, config: [Value: Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_win_set_config",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .dictionary(config),
      ]
    )
  }

  func nvimWinGetConfig(windowID: Window.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_get_config",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinGetConfigFast(windowID: Window.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_win_get_config",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinGetBuf(windowID: Window.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_get_buf",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinGetBufFast(windowID: Window.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_win_get_buf",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinSetBuf(windowID: Window.ID, bufferID: Buffer.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_set_buf",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimWinSetBufFast(windowID: Window.ID, bufferID: Buffer.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_win_set_buf",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .ext(type: References.Buffer.type, data: bufferID.data),
      ]
    )
  }

  func nvimWinGetCursor(windowID: Window.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_get_cursor",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinGetCursorFast(windowID: Window.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_win_get_cursor",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinSetCursor(windowID: Window.ID, pos: [Value]) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_set_cursor",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .array(pos),
      ]
    )
  }

  func nvimWinSetCursorFast(windowID: Window.ID, pos: [Value]) async throws {
    try await rpc.fastCall(
      method: "nvim_win_set_cursor",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .array(pos),
      ]
    )
  }

  func nvimWinGetHeight(windowID: Window.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_get_height",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinGetHeightFast(windowID: Window.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_win_get_height",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinSetHeight(windowID: Window.ID, height: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_set_height",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .integer(height),
      ]
    )
  }

  func nvimWinSetHeightFast(windowID: Window.ID, height: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_win_set_height",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .integer(height),
      ]
    )
  }

  func nvimWinGetWidth(windowID: Window.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_get_width",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinGetWidthFast(windowID: Window.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_win_get_width",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinSetWidth(windowID: Window.ID, width: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_set_width",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .integer(width),
      ]
    )
  }

  func nvimWinSetWidthFast(windowID: Window.ID, width: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_win_set_width",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .integer(width),
      ]
    )
  }

  func nvimWinGetVar(windowID: Window.ID, name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_get_var",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .string(name),
      ]
    )
  }

  func nvimWinGetVarFast(windowID: Window.ID, name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_win_get_var",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .string(name),
      ]
    )
  }

  func nvimWinSetVar(windowID: Window.ID, name: String, value: Value) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_set_var",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .string(name),
        value,
      ]
    )
  }

  func nvimWinSetVarFast(windowID: Window.ID, name: String, value: Value) async throws {
    try await rpc.fastCall(
      method: "nvim_win_set_var",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .string(name),
        value,
      ]
    )
  }

  func nvimWinDelVar(windowID: Window.ID, name: String) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_del_var",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .string(name),
      ]
    )
  }

  func nvimWinDelVarFast(windowID: Window.ID, name: String) async throws {
    try await rpc.fastCall(
      method: "nvim_win_del_var",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .string(name),
      ]
    )
  }

  func nvimWinGetPosition(windowID: Window.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_get_position",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinGetPositionFast(windowID: Window.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_win_get_position",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinGetTabpage(windowID: Window.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_get_tabpage",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinGetTabpageFast(windowID: Window.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_win_get_tabpage",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinGetNumber(windowID: Window.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_get_number",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinGetNumberFast(windowID: Window.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_win_get_number",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinIsValid(windowID: Window.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_is_valid",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinIsValidFast(windowID: Window.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_win_is_valid",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinHide(windowID: Window.ID) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_hide",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinHideFast(windowID: Window.ID) async throws {
    try await rpc.fastCall(
      method: "nvim_win_hide",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
      ]
    )
  }

  func nvimWinClose(windowID: Window.ID, force: Bool) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_close",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .boolean(force),
      ]
    )
  }

  func nvimWinCloseFast(windowID: Window.ID, force: Bool) async throws {
    try await rpc.fastCall(
      method: "nvim_win_close",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .boolean(force),
      ]
    )
  }

  func nvimWinCall(windowID: Window.ID, fun: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_call",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .integer(fun),
      ]
    )
  }

  func nvimWinCallFast(windowID: Window.ID, fun: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_win_call",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .integer(fun),
      ]
    )
  }

  func nvimWinSetHlNs(windowID: Window.ID, nsID: Int) async throws -> Message.Response.Result {
    try await rpc.call(
      method: "nvim_win_set_hl_ns",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .integer(nsID),
      ]
    )
  }

  func nvimWinSetHlNsFast(windowID: Window.ID, nsID: Int) async throws {
    try await rpc.fastCall(
      method: "nvim_win_set_hl_ns",
      withParameters: [
        .ext(type: References.Window.type, data: windowID.data),
        .integer(nsID),
      ]
    )
  }
}
