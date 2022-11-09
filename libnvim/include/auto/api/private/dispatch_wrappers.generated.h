Object handle_nvim_get_autocmds(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_autocmds", channel_id);
#endif
  Object ret = NIL;
  KeyDict_get_autocmds arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeDictionary) {
    memset(&arg_1, 0, sizeof(*&arg_1));
    if (!api_dict_to_keydict(&arg_1, KeyDict_get_autocmds_get_field, args.items[0].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[0].type == kObjectTypeArray && args.items[0].data.array.size == 0) {
    memset(&arg_1, 0, sizeof(*&arg_1));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_autocmds, expecting Dict(get_autocmds) *");
    goto cleanup;
  }

  Array rv = nvim_get_autocmds(&arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_create_autocmd(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_create_autocmd", channel_id);
#endif
  Object ret = NIL;
  Object arg_1;
  KeyDict_create_autocmd arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  arg_1 = args.items[0];

  if (args.items[1].type == kObjectTypeDictionary) {
    memset(&arg_2, 0, sizeof(*&arg_2));
    if (!api_dict_to_keydict(&arg_2, KeyDict_create_autocmd_get_field, args.items[1].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[1].type == kObjectTypeArray && args.items[1].data.array.size == 0) {
    memset(&arg_2, 0, sizeof(*&arg_2));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_create_autocmd, expecting Dict(create_autocmd) *");
    goto cleanup;
  }

  Integer rv = nvim_create_autocmd(channel_id, arg_1, &arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_del_autocmd(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_del_autocmd", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_del_autocmd, expecting Integer");
    goto cleanup;
  }

  nvim_del_autocmd(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_clear_autocmds(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_clear_autocmds", channel_id);
#endif
  Object ret = NIL;
  KeyDict_clear_autocmds arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeDictionary) {
    memset(&arg_1, 0, sizeof(*&arg_1));
    if (!api_dict_to_keydict(&arg_1, KeyDict_clear_autocmds_get_field, args.items[0].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[0].type == kObjectTypeArray && args.items[0].data.array.size == 0) {
    memset(&arg_1, 0, sizeof(*&arg_1));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_clear_autocmds, expecting Dict(clear_autocmds) *");
    goto cleanup;
  }

  nvim_clear_autocmds(&arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_create_augroup(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_create_augroup", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  KeyDict_create_augroup arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_create_augroup, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeDictionary) {
    memset(&arg_2, 0, sizeof(*&arg_2));
    if (!api_dict_to_keydict(&arg_2, KeyDict_create_augroup_get_field, args.items[1].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[1].type == kObjectTypeArray && args.items[1].data.array.size == 0) {
    memset(&arg_2, 0, sizeof(*&arg_2));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_create_augroup, expecting Dict(create_augroup) *");
    goto cleanup;
  }

  Integer rv = nvim_create_augroup(channel_id, arg_1, &arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_del_augroup_by_id(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_del_augroup_by_id", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_del_augroup_by_id, expecting Integer");
    goto cleanup;
  }

  nvim_del_augroup_by_id(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_del_augroup_by_name(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_del_augroup_by_name", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_del_augroup_by_name, expecting String");
    goto cleanup;
  }

  nvim_del_augroup_by_name(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_exec_autocmds(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_exec_autocmds", channel_id);
#endif
  Object ret = NIL;
  Object arg_1;
  KeyDict_exec_autocmds arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  arg_1 = args.items[0];

  if (args.items[1].type == kObjectTypeDictionary) {
    memset(&arg_2, 0, sizeof(*&arg_2));
    if (!api_dict_to_keydict(&arg_2, KeyDict_exec_autocmds_get_field, args.items[1].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[1].type == kObjectTypeArray && args.items[1].data.array.size == 0) {
    memset(&arg_2, 0, sizeof(*&arg_2));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_exec_autocmds, expecting Dict(exec_autocmds) *");
    goto cleanup;
  }

  nvim_exec_autocmds(arg_1, &arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_buf_line_count(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_line_count", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_line_count, expecting Buffer");
    goto cleanup;
  }

  Integer rv = nvim_buf_line_count(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_attach(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_attach", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Boolean arg_2;
  Dictionary arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_attach, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBoolean) {
    arg_2 = args.items[1].data.boolean;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_attach, expecting Boolean");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeDictionary) {
    arg_3 = args.items[2].data.dictionary;
  } else if (args.items[2].type == kObjectTypeArray && args.items[2].data.array.size == 0) {
    arg_3 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_attach, expecting DictionaryOf(LuaRef)");
    goto cleanup;
  }

  Boolean rv = nvim_buf_attach(channel_id, arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = BOOLEAN_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_detach(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_detach", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_detach, expecting Buffer");
    goto cleanup;
  }

  Boolean rv = nvim_buf_detach(channel_id, arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = BOOLEAN_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim__buf_redraw_range(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__buf_redraw_range", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Integer arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim__buf_redraw_range, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim__buf_redraw_range, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim__buf_redraw_range, expecting Integer");
    goto cleanup;
  }

  nvim__buf_redraw_range(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_buf_get_lines(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_get_lines", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Integer arg_3;
  Boolean arg_4;

  if (args.size != 4) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 4 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_get_lines, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_get_lines, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_get_lines, expecting Integer");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeBoolean) {
    arg_4 = args.items[3].data.boolean;
  } else if (args.items[3].type == kObjectTypeInteger && args.items[3].data.integer >= 0) {
    arg_4 = (handle_T)args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_buf_get_lines, expecting Boolean");
    goto cleanup;
  }

  ArrayOf(String) rv = nvim_buf_get_lines(channel_id, arg_1, arg_2, arg_3, arg_4, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_set_lines(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_set_lines", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Integer arg_3;
  Boolean arg_4;
  Array arg_5;

  if (args.size != 5) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 5 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_set_lines, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_set_lines, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_set_lines, expecting Integer");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeBoolean) {
    arg_4 = args.items[3].data.boolean;
  } else if (args.items[3].type == kObjectTypeInteger && args.items[3].data.integer >= 0) {
    arg_4 = (handle_T)args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_buf_set_lines, expecting Boolean");
    goto cleanup;
  }

  if (args.items[4].type == kObjectTypeArray) {
    arg_5 = args.items[4].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 5 when calling nvim_buf_set_lines, expecting ArrayOf(String)");
    goto cleanup;
  }

  if (textlock != 0) {
    api_set_error(error, kErrorTypeException, "%s", e_textlock);
    goto cleanup;
  }

  nvim_buf_set_lines(channel_id, arg_1, arg_2, arg_3, arg_4, arg_5, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_buf_set_text(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_set_text", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Integer arg_3;
  Integer arg_4;
  Integer arg_5;
  Array arg_6;

  if (args.size != 6) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 6 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_set_text, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_set_text, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_set_text, expecting Integer");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeInteger) {
    arg_4 = args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_buf_set_text, expecting Integer");
    goto cleanup;
  }

  if (args.items[4].type == kObjectTypeInteger) {
    arg_5 = args.items[4].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 5 when calling nvim_buf_set_text, expecting Integer");
    goto cleanup;
  }

  if (args.items[5].type == kObjectTypeArray) {
    arg_6 = args.items[5].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 6 when calling nvim_buf_set_text, expecting ArrayOf(String)");
    goto cleanup;
  }

  nvim_buf_set_text(channel_id, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_buf_get_text(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_get_text", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Integer arg_3;
  Integer arg_4;
  Integer arg_5;
  Dictionary arg_6;

  if (args.size != 6) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 6 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_get_text, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_get_text, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_get_text, expecting Integer");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeInteger) {
    arg_4 = args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_buf_get_text, expecting Integer");
    goto cleanup;
  }

  if (args.items[4].type == kObjectTypeInteger) {
    arg_5 = args.items[4].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 5 when calling nvim_buf_get_text, expecting Integer");
    goto cleanup;
  }

  if (args.items[5].type == kObjectTypeDictionary) {
    arg_6 = args.items[5].data.dictionary;
  } else if (args.items[5].type == kObjectTypeArray && args.items[5].data.array.size == 0) {
    arg_6 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 6 when calling nvim_buf_get_text, expecting Dictionary");
    goto cleanup;
  }

  ArrayOf(String) rv = nvim_buf_get_text(channel_id, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_get_offset(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_get_offset", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_get_offset, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_get_offset, expecting Integer");
    goto cleanup;
  }

  Integer rv = nvim_buf_get_offset(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_get_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_get_var", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_get_var, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_get_var, expecting String");
    goto cleanup;
  }

  Object rv = nvim_buf_get_var(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_get_changedtick(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_get_changedtick", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_get_changedtick, expecting Buffer");
    goto cleanup;
  }

  Integer rv = nvim_buf_get_changedtick(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_get_keymap(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_get_keymap", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_get_keymap, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_get_keymap, expecting String");
    goto cleanup;
  }

  ArrayOf(Dictionary) rv = nvim_buf_get_keymap(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_set_keymap(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_set_keymap", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;
  String arg_3;
  String arg_4;
  KeyDict_keymap arg_5;

  if (args.size != 5) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 5 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_set_keymap, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_set_keymap, expecting String");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeString) {
    arg_3 = args.items[2].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_set_keymap, expecting String");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeString) {
    arg_4 = args.items[3].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_buf_set_keymap, expecting String");
    goto cleanup;
  }

  if (args.items[4].type == kObjectTypeDictionary) {
    memset(&arg_5, 0, sizeof(*&arg_5));
    if (!api_dict_to_keydict(&arg_5, KeyDict_keymap_get_field, args.items[4].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[4].type == kObjectTypeArray && args.items[4].data.array.size == 0) {
    memset(&arg_5, 0, sizeof(*&arg_5));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 5 when calling nvim_buf_set_keymap, expecting Dict(keymap) *");
    goto cleanup;
  }

  nvim_buf_set_keymap(channel_id, arg_1, arg_2, arg_3, arg_4, &arg_5, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_buf_del_keymap(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_del_keymap", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;
  String arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_del_keymap, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_del_keymap, expecting String");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeString) {
    arg_3 = args.items[2].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_del_keymap, expecting String");
    goto cleanup;
  }

  nvim_buf_del_keymap(channel_id, arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_buf_set_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_set_var", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;
  Object arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_set_var, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_set_var, expecting String");
    goto cleanup;
  }

  arg_3 = args.items[2];

  nvim_buf_set_var(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_buf_del_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_del_var", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_del_var, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_del_var, expecting String");
    goto cleanup;
  }

  nvim_buf_del_var(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_buf_get_name(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_get_name", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_get_name, expecting Buffer");
    goto cleanup;
  }

  String rv = nvim_buf_get_name(arg_1, arena, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = STRING_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_set_name(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_set_name", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_set_name, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_set_name, expecting String");
    goto cleanup;
  }

  nvim_buf_set_name(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_buf_is_loaded(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_is_loaded", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_is_loaded, expecting Buffer");
    goto cleanup;
  }

  Boolean rv = nvim_buf_is_loaded(arg_1);

  ret = BOOLEAN_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_delete(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_delete", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Dictionary arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_delete, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeDictionary) {
    arg_2 = args.items[1].data.dictionary;
  } else if (args.items[1].type == kObjectTypeArray && args.items[1].data.array.size == 0) {
    arg_2 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_delete, expecting Dictionary");
    goto cleanup;
  }

  if (textlock != 0) {
    api_set_error(error, kErrorTypeException, "%s", e_textlock);
    goto cleanup;
  }

  nvim_buf_delete(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_buf_is_valid(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_is_valid", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_is_valid, expecting Buffer");
    goto cleanup;
  }

  Boolean rv = nvim_buf_is_valid(arg_1);

  ret = BOOLEAN_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_del_mark(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_del_mark", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_del_mark, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_del_mark, expecting String");
    goto cleanup;
  }

  Boolean rv = nvim_buf_del_mark(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = BOOLEAN_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_set_mark(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_set_mark", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;
  Integer arg_3;
  Integer arg_4;
  Dictionary arg_5;

  if (args.size != 5) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 5 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_set_mark, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_set_mark, expecting String");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_set_mark, expecting Integer");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeInteger) {
    arg_4 = args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_buf_set_mark, expecting Integer");
    goto cleanup;
  }

  if (args.items[4].type == kObjectTypeDictionary) {
    arg_5 = args.items[4].data.dictionary;
  } else if (args.items[4].type == kObjectTypeArray && args.items[4].data.array.size == 0) {
    arg_5 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 5 when calling nvim_buf_set_mark, expecting Dictionary");
    goto cleanup;
  }

  Boolean rv = nvim_buf_set_mark(arg_1, arg_2, arg_3, arg_4, arg_5, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = BOOLEAN_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_get_mark(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_get_mark", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_get_mark, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_get_mark, expecting String");
    goto cleanup;
  }

  ArrayOf(Integer, 2) rv = nvim_buf_get_mark(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim__buf_stats(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__buf_stats", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim__buf_stats, expecting Buffer");
    goto cleanup;
  }

  Dictionary rv = nvim__buf_stats(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_parse_cmd(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_parse_cmd", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Dictionary arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_parse_cmd, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeDictionary) {
    arg_2 = args.items[1].data.dictionary;
  } else if (args.items[1].type == kObjectTypeArray && args.items[1].data.array.size == 0) {
    arg_2 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_parse_cmd, expecting Dictionary");
    goto cleanup;
  }

  Dictionary rv = nvim_parse_cmd(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_cmd(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_cmd", channel_id);
#endif
  Object ret = NIL;
  KeyDict_cmd arg_1;
  KeyDict_cmd_opts arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeDictionary) {
    memset(&arg_1, 0, sizeof(*&arg_1));
    if (!api_dict_to_keydict(&arg_1, KeyDict_cmd_get_field, args.items[0].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[0].type == kObjectTypeArray && args.items[0].data.array.size == 0) {
    memset(&arg_1, 0, sizeof(*&arg_1));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_cmd, expecting Dict(cmd) *");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeDictionary) {
    memset(&arg_2, 0, sizeof(*&arg_2));
    if (!api_dict_to_keydict(&arg_2, KeyDict_cmd_opts_get_field, args.items[1].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[1].type == kObjectTypeArray && args.items[1].data.array.size == 0) {
    memset(&arg_2, 0, sizeof(*&arg_2));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_cmd, expecting Dict(cmd_opts) *");
    goto cleanup;
  }

  String rv = nvim_cmd(channel_id, &arg_1, &arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = STRING_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_create_user_command(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_create_user_command", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Object arg_2;
  KeyDict_user_command arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_create_user_command, expecting String");
    goto cleanup;
  }

  arg_2 = args.items[1];

  if (args.items[2].type == kObjectTypeDictionary) {
    memset(&arg_3, 0, sizeof(*&arg_3));
    if (!api_dict_to_keydict(&arg_3, KeyDict_user_command_get_field, args.items[2].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[2].type == kObjectTypeArray && args.items[2].data.array.size == 0) {
    memset(&arg_3, 0, sizeof(*&arg_3));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_create_user_command, expecting Dict(user_command) *");
    goto cleanup;
  }

  nvim_create_user_command(arg_1, arg_2, &arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_del_user_command(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_del_user_command", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_del_user_command, expecting String");
    goto cleanup;
  }

  nvim_del_user_command(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_buf_create_user_command(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_create_user_command", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;
  Object arg_3;
  KeyDict_user_command arg_4;

  if (args.size != 4) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 4 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_create_user_command, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_create_user_command, expecting String");
    goto cleanup;
  }

  arg_3 = args.items[2];

  if (args.items[3].type == kObjectTypeDictionary) {
    memset(&arg_4, 0, sizeof(*&arg_4));
    if (!api_dict_to_keydict(&arg_4, KeyDict_user_command_get_field, args.items[3].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[3].type == kObjectTypeArray && args.items[3].data.array.size == 0) {
    memset(&arg_4, 0, sizeof(*&arg_4));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_buf_create_user_command, expecting Dict(user_command) *");
    goto cleanup;
  }

  nvim_buf_create_user_command(arg_1, arg_2, arg_3, &arg_4, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_buf_del_user_command(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_del_user_command", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_del_user_command, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_del_user_command, expecting String");
    goto cleanup;
  }

  nvim_buf_del_user_command(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_get_commands(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_commands", channel_id);
#endif
  Object ret = NIL;
  KeyDict_get_commands arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeDictionary) {
    memset(&arg_1, 0, sizeof(*&arg_1));
    if (!api_dict_to_keydict(&arg_1, KeyDict_get_commands_get_field, args.items[0].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[0].type == kObjectTypeArray && args.items[0].data.array.size == 0) {
    memset(&arg_1, 0, sizeof(*&arg_1));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_commands, expecting Dict(get_commands) *");
    goto cleanup;
  }

  Dictionary rv = nvim_get_commands(&arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_get_commands(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_get_commands", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  KeyDict_get_commands arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_get_commands, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeDictionary) {
    memset(&arg_2, 0, sizeof(*&arg_2));
    if (!api_dict_to_keydict(&arg_2, KeyDict_get_commands_get_field, args.items[1].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[1].type == kObjectTypeArray && args.items[1].data.array.size == 0) {
    memset(&arg_2, 0, sizeof(*&arg_2));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_get_commands, expecting Dict(get_commands) *");
    goto cleanup;
  }

  Dictionary rv = nvim_buf_get_commands(arg_1, &arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_command_output(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_command_output", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_command_output, expecting String");
    goto cleanup;
  }

  String rv = nvim_command_output(channel_id, arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = STRING_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_execute_lua(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_execute_lua", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Array arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_execute_lua, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeArray) {
    arg_2 = args.items[1].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_execute_lua, expecting Array");
    goto cleanup;
  }

  Object rv = nvim_execute_lua(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_get_number(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_get_number", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_get_number, expecting Buffer");
    goto cleanup;
  }

  Integer rv = nvim_buf_get_number(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_clear_highlight(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_clear_highlight", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Integer arg_3;
  Integer arg_4;

  if (args.size != 4) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 4 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_clear_highlight, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_clear_highlight, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_clear_highlight, expecting Integer");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeInteger) {
    arg_4 = args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_buf_clear_highlight, expecting Integer");
    goto cleanup;
  }

  nvim_buf_clear_highlight(arg_1, arg_2, arg_3, arg_4, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_buf_set_virtual_text(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_set_virtual_text", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Integer arg_3;
  Array arg_4;
  Dictionary arg_5;

  if (args.size != 5) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 5 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_set_virtual_text, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_set_virtual_text, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_set_virtual_text, expecting Integer");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeArray) {
    arg_4 = args.items[3].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_buf_set_virtual_text, expecting Array");
    goto cleanup;
  }

  if (args.items[4].type == kObjectTypeDictionary) {
    arg_5 = args.items[4].data.dictionary;
  } else if (args.items[4].type == kObjectTypeArray && args.items[4].data.array.size == 0) {
    arg_5 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 5 when calling nvim_buf_set_virtual_text, expecting Dictionary");
    goto cleanup;
  }

  Integer rv = nvim_buf_set_virtual_text(arg_1, arg_2, arg_3, arg_4, arg_5, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_buffer_insert(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke buffer_insert", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Array arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling buffer_insert, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling buffer_insert, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeArray) {
    arg_3 = args.items[2].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling buffer_insert, expecting ArrayOf(String)");
    goto cleanup;
  }

  buffer_insert(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_buffer_get_line(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke buffer_get_line", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling buffer_get_line, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling buffer_get_line, expecting Integer");
    goto cleanup;
  }

  String rv = buffer_get_line(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = STRING_OBJ(rv);

cleanup:
  return ret;
}

Object handle_buffer_set_line(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke buffer_set_line", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  String arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling buffer_set_line, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling buffer_set_line, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeString) {
    arg_3 = args.items[2].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling buffer_set_line, expecting String");
    goto cleanup;
  }

  buffer_set_line(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_buffer_del_line(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke buffer_del_line", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling buffer_del_line, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling buffer_del_line, expecting Integer");
    goto cleanup;
  }

  buffer_del_line(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_buffer_get_line_slice(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke buffer_get_line_slice", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Integer arg_3;
  Boolean arg_4;
  Boolean arg_5;

  if (args.size != 5) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 5 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling buffer_get_line_slice, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling buffer_get_line_slice, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling buffer_get_line_slice, expecting Integer");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeBoolean) {
    arg_4 = args.items[3].data.boolean;
  } else if (args.items[3].type == kObjectTypeInteger && args.items[3].data.integer >= 0) {
    arg_4 = (handle_T)args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling buffer_get_line_slice, expecting Boolean");
    goto cleanup;
  }

  if (args.items[4].type == kObjectTypeBoolean) {
    arg_5 = args.items[4].data.boolean;
  } else if (args.items[4].type == kObjectTypeInteger && args.items[4].data.integer >= 0) {
    arg_5 = (handle_T)args.items[4].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 5 when calling buffer_get_line_slice, expecting Boolean");
    goto cleanup;
  }

  ArrayOf(String) rv = buffer_get_line_slice(arg_1, arg_2, arg_3, arg_4, arg_5, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_buffer_set_line_slice(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke buffer_set_line_slice", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Integer arg_3;
  Boolean arg_4;
  Boolean arg_5;
  Array arg_6;

  if (args.size != 6) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 6 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling buffer_set_line_slice, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling buffer_set_line_slice, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling buffer_set_line_slice, expecting Integer");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeBoolean) {
    arg_4 = args.items[3].data.boolean;
  } else if (args.items[3].type == kObjectTypeInteger && args.items[3].data.integer >= 0) {
    arg_4 = (handle_T)args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling buffer_set_line_slice, expecting Boolean");
    goto cleanup;
  }

  if (args.items[4].type == kObjectTypeBoolean) {
    arg_5 = args.items[4].data.boolean;
  } else if (args.items[4].type == kObjectTypeInteger && args.items[4].data.integer >= 0) {
    arg_5 = (handle_T)args.items[4].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 5 when calling buffer_set_line_slice, expecting Boolean");
    goto cleanup;
  }

  if (args.items[5].type == kObjectTypeArray) {
    arg_6 = args.items[5].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 6 when calling buffer_set_line_slice, expecting ArrayOf(String)");
    goto cleanup;
  }

  buffer_set_line_slice(arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_buffer_set_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke buffer_set_var", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;
  Object arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling buffer_set_var, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling buffer_set_var, expecting String");
    goto cleanup;
  }

  arg_3 = args.items[2];

  Object rv = buffer_set_var(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_buffer_del_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke buffer_del_var", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling buffer_del_var, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling buffer_del_var, expecting String");
    goto cleanup;
  }

  Object rv = buffer_del_var(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_window_set_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke window_set_var", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  String arg_2;
  Object arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling window_set_var, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling window_set_var, expecting String");
    goto cleanup;
  }

  arg_3 = args.items[2];

  Object rv = window_set_var(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_window_del_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke window_del_var", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling window_del_var, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling window_del_var, expecting String");
    goto cleanup;
  }

  Object rv = window_del_var(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_tabpage_set_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke tabpage_set_var", channel_id);
#endif
  Object ret = NIL;
  Tabpage arg_1;
  String arg_2;
  Object arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeTabpage && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling tabpage_set_var, expecting Tabpage");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling tabpage_set_var, expecting String");
    goto cleanup;
  }

  arg_3 = args.items[2];

  Object rv = tabpage_set_var(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_tabpage_del_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke tabpage_del_var", channel_id);
#endif
  Object ret = NIL;
  Tabpage arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeTabpage && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling tabpage_del_var, expecting Tabpage");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling tabpage_del_var, expecting String");
    goto cleanup;
  }

  Object rv = tabpage_del_var(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_vim_set_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke vim_set_var", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Object arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling vim_set_var, expecting String");
    goto cleanup;
  }

  arg_2 = args.items[1];

  Object rv = vim_set_var(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_vim_del_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke vim_del_var", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling vim_del_var, expecting String");
    goto cleanup;
  }

  Object rv = vim_del_var(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_create_namespace(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_create_namespace", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_create_namespace, expecting String");
    goto cleanup;
  }

  Integer rv = nvim_create_namespace(arg_1);

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_namespaces(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_namespaces", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  Dictionary rv = nvim_get_namespaces();

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_get_extmark_by_id(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_get_extmark_by_id", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Integer arg_3;
  Dictionary arg_4;

  if (args.size != 4) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 4 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_get_extmark_by_id, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_get_extmark_by_id, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_get_extmark_by_id, expecting Integer");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeDictionary) {
    arg_4 = args.items[3].data.dictionary;
  } else if (args.items[3].type == kObjectTypeArray && args.items[3].data.array.size == 0) {
    arg_4 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_buf_get_extmark_by_id, expecting Dictionary");
    goto cleanup;
  }

  ArrayOf(Integer) rv = nvim_buf_get_extmark_by_id(arg_1, arg_2, arg_3, arg_4, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_get_extmarks(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_get_extmarks", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Object arg_3;
  Object arg_4;
  Dictionary arg_5;

  if (args.size != 5) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 5 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_get_extmarks, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_get_extmarks, expecting Integer");
    goto cleanup;
  }

  arg_3 = args.items[2];

  arg_4 = args.items[3];

  if (args.items[4].type == kObjectTypeDictionary) {
    arg_5 = args.items[4].data.dictionary;
  } else if (args.items[4].type == kObjectTypeArray && args.items[4].data.array.size == 0) {
    arg_5 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 5 when calling nvim_buf_get_extmarks, expecting Dictionary");
    goto cleanup;
  }

  Array rv = nvim_buf_get_extmarks(arg_1, arg_2, arg_3, arg_4, arg_5, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_set_extmark(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_set_extmark", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Integer arg_3;
  Integer arg_4;
  KeyDict_set_extmark arg_5;

  if (args.size != 5) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 5 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_set_extmark, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_set_extmark, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_set_extmark, expecting Integer");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeInteger) {
    arg_4 = args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_buf_set_extmark, expecting Integer");
    goto cleanup;
  }

  if (args.items[4].type == kObjectTypeDictionary) {
    memset(&arg_5, 0, sizeof(*&arg_5));
    if (!api_dict_to_keydict(&arg_5, KeyDict_set_extmark_get_field, args.items[4].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[4].type == kObjectTypeArray && args.items[4].data.array.size == 0) {
    memset(&arg_5, 0, sizeof(*&arg_5));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 5 when calling nvim_buf_set_extmark, expecting Dict(set_extmark) *");
    goto cleanup;
  }

  Integer rv = nvim_buf_set_extmark(arg_1, arg_2, arg_3, arg_4, &arg_5, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_del_extmark(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_del_extmark", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Integer arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_del_extmark, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_del_extmark, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_del_extmark, expecting Integer");
    goto cleanup;
  }

  Boolean rv = nvim_buf_del_extmark(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = BOOLEAN_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_add_highlight(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_add_highlight", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  String arg_3;
  Integer arg_4;
  Integer arg_5;
  Integer arg_6;

  if (args.size != 6) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 6 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_add_highlight, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_add_highlight, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeString) {
    arg_3 = args.items[2].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_add_highlight, expecting String");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeInteger) {
    arg_4 = args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_buf_add_highlight, expecting Integer");
    goto cleanup;
  }

  if (args.items[4].type == kObjectTypeInteger) {
    arg_5 = args.items[4].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 5 when calling nvim_buf_add_highlight, expecting Integer");
    goto cleanup;
  }

  if (args.items[5].type == kObjectTypeInteger) {
    arg_6 = args.items[5].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 6 when calling nvim_buf_add_highlight, expecting Integer");
    goto cleanup;
  }

  Integer rv = nvim_buf_add_highlight(arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_clear_namespace(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_clear_namespace", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Integer arg_2;
  Integer arg_3;
  Integer arg_4;

  if (args.size != 4) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 4 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_clear_namespace, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_clear_namespace, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_buf_clear_namespace, expecting Integer");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeInteger) {
    arg_4 = args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_buf_clear_namespace, expecting Integer");
    goto cleanup;
  }

  nvim_buf_clear_namespace(arg_1, arg_2, arg_3, arg_4, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_get_option_value(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_option_value", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  KeyDict_option arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_option_value, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeDictionary) {
    memset(&arg_2, 0, sizeof(*&arg_2));
    if (!api_dict_to_keydict(&arg_2, KeyDict_option_get_field, args.items[1].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[1].type == kObjectTypeArray && args.items[1].data.array.size == 0) {
    memset(&arg_2, 0, sizeof(*&arg_2));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_get_option_value, expecting Dict(option) *");
    goto cleanup;
  }

  Object rv = nvim_get_option_value(arg_1, &arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_set_option_value(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_option_value", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Object arg_2;
  KeyDict_option arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_option_value, expecting String");
    goto cleanup;
  }

  arg_2 = args.items[1];

  if (args.items[2].type == kObjectTypeDictionary) {
    memset(&arg_3, 0, sizeof(*&arg_3));
    if (!api_dict_to_keydict(&arg_3, KeyDict_option_get_field, args.items[2].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[2].type == kObjectTypeArray && args.items[2].data.array.size == 0) {
    memset(&arg_3, 0, sizeof(*&arg_3));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_set_option_value, expecting Dict(option) *");
    goto cleanup;
  }

  nvim_set_option_value(arg_1, arg_2, &arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_get_all_options_info(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_all_options_info", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  Dictionary rv = nvim_get_all_options_info(error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_option_info(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_option_info", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_option_info, expecting String");
    goto cleanup;
  }

  Dictionary rv = nvim_get_option_info(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_set_option(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_option", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Object arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_option, expecting String");
    goto cleanup;
  }

  arg_2 = args.items[1];

  nvim_set_option(channel_id, arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_get_option(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_option", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_option, expecting String");
    goto cleanup;
  }

  Object rv = nvim_get_option(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_get_option(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_get_option", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_get_option, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_get_option, expecting String");
    goto cleanup;
  }

  Object rv = nvim_buf_get_option(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_buf_set_option(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_buf_set_option", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  String arg_2;
  Object arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_buf_set_option, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_buf_set_option, expecting String");
    goto cleanup;
  }

  arg_3 = args.items[2];

  nvim_buf_set_option(channel_id, arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_win_get_option(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_get_option", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_get_option, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_win_get_option, expecting String");
    goto cleanup;
  }

  Object rv = nvim_win_get_option(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_win_set_option(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_set_option", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  String arg_2;
  Object arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_set_option, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_win_set_option, expecting String");
    goto cleanup;
  }

  arg_3 = args.items[2];

  nvim_win_set_option(channel_id, arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_tabpage_list_wins(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_tabpage_list_wins", channel_id);
#endif
  Object ret = NIL;
  Tabpage arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeTabpage && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_tabpage_list_wins, expecting Tabpage");
    goto cleanup;
  }

  ArrayOf(Window) rv = nvim_tabpage_list_wins(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_tabpage_get_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_tabpage_get_var", channel_id);
#endif
  Object ret = NIL;
  Tabpage arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeTabpage && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_tabpage_get_var, expecting Tabpage");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_tabpage_get_var, expecting String");
    goto cleanup;
  }

  Object rv = nvim_tabpage_get_var(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_tabpage_set_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_tabpage_set_var", channel_id);
#endif
  Object ret = NIL;
  Tabpage arg_1;
  String arg_2;
  Object arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeTabpage && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_tabpage_set_var, expecting Tabpage");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_tabpage_set_var, expecting String");
    goto cleanup;
  }

  arg_3 = args.items[2];

  nvim_tabpage_set_var(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_tabpage_del_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_tabpage_del_var", channel_id);
#endif
  Object ret = NIL;
  Tabpage arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeTabpage && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_tabpage_del_var, expecting Tabpage");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_tabpage_del_var, expecting String");
    goto cleanup;
  }

  nvim_tabpage_del_var(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_tabpage_get_win(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_tabpage_get_win", channel_id);
#endif
  Object ret = NIL;
  Tabpage arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeTabpage && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_tabpage_get_win, expecting Tabpage");
    goto cleanup;
  }

  Window rv = nvim_tabpage_get_win(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = WINDOW_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_tabpage_get_number(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_tabpage_get_number", channel_id);
#endif
  Object ret = NIL;
  Tabpage arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeTabpage && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_tabpage_get_number, expecting Tabpage");
    goto cleanup;
  }

  Integer rv = nvim_tabpage_get_number(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_tabpage_is_valid(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_tabpage_is_valid", channel_id);
#endif
  Object ret = NIL;
  Tabpage arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeTabpage && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_tabpage_is_valid, expecting Tabpage");
    goto cleanup;
  }

  Boolean rv = nvim_tabpage_is_valid(arg_1);

  ret = BOOLEAN_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_ui_attach(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_ui_attach", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;
  Integer arg_2;
  Dictionary arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_ui_attach, expecting Integer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_ui_attach, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeDictionary) {
    arg_3 = args.items[2].data.dictionary;
  } else if (args.items[2].type == kObjectTypeArray && args.items[2].data.array.size == 0) {
    arg_3 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_ui_attach, expecting Dictionary");
    goto cleanup;
  }

  nvim_ui_attach(channel_id, arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_ui_attach(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke ui_attach", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;
  Integer arg_2;
  Boolean arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling ui_attach, expecting Integer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling ui_attach, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeBoolean) {
    arg_3 = args.items[2].data.boolean;
  } else if (args.items[2].type == kObjectTypeInteger && args.items[2].data.integer >= 0) {
    arg_3 = (handle_T)args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling ui_attach, expecting Boolean");
    goto cleanup;
  }

  ui_attach(channel_id, arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_ui_detach(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_ui_detach", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  nvim_ui_detach(channel_id, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_ui_try_resize(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_ui_try_resize", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;
  Integer arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_ui_try_resize, expecting Integer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_ui_try_resize, expecting Integer");
    goto cleanup;
  }

  nvim_ui_try_resize(channel_id, arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_ui_set_option(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_ui_set_option", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Object arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_ui_set_option, expecting String");
    goto cleanup;
  }

  arg_2 = args.items[1];

  nvim_ui_set_option(channel_id, arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_ui_try_resize_grid(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_ui_try_resize_grid", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;
  Integer arg_2;
  Integer arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_ui_try_resize_grid, expecting Integer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_ui_try_resize_grid, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_ui_try_resize_grid, expecting Integer");
    goto cleanup;
  }

  nvim_ui_try_resize_grid(channel_id, arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_ui_pum_set_height(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_ui_pum_set_height", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_ui_pum_set_height, expecting Integer");
    goto cleanup;
  }

  nvim_ui_pum_set_height(channel_id, arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_ui_pum_set_bounds(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_ui_pum_set_bounds", channel_id);
#endif
  Object ret = NIL;
  Float arg_1;
  Float arg_2;
  Float arg_3;
  Float arg_4;

  if (args.size != 4) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 4 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeFloat) {
    arg_1 = args.items[0].data.floating;
  } else if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = (Float)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_ui_pum_set_bounds, expecting Float");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeFloat) {
    arg_2 = args.items[1].data.floating;
  } else if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = (Float)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_ui_pum_set_bounds, expecting Float");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeFloat) {
    arg_3 = args.items[2].data.floating;
  } else if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = (Float)args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_ui_pum_set_bounds, expecting Float");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeFloat) {
    arg_4 = args.items[3].data.floating;
  } else if (args.items[3].type == kObjectTypeInteger) {
    arg_4 = (Float)args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_ui_pum_set_bounds, expecting Float");
    goto cleanup;
  }

  nvim_ui_pum_set_bounds(channel_id, arg_1, arg_2, arg_3, arg_4, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_get_hl_by_name(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_hl_by_name", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Boolean arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_hl_by_name, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBoolean) {
    arg_2 = args.items[1].data.boolean;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_get_hl_by_name, expecting Boolean");
    goto cleanup;
  }

  Dictionary rv = nvim_get_hl_by_name(arg_1, arg_2, arena, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_hl_by_id(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_hl_by_id", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;
  Boolean arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_hl_by_id, expecting Integer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBoolean) {
    arg_2 = args.items[1].data.boolean;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_get_hl_by_id, expecting Boolean");
    goto cleanup;
  }

  Dictionary rv = nvim_get_hl_by_id(arg_1, arg_2, arena, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_hl_id_by_name(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_hl_id_by_name", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_hl_id_by_name, expecting String");
    goto cleanup;
  }

  Integer rv = nvim_get_hl_id_by_name(arg_1);

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim__get_hl_defs(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__get_hl_defs", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim__get_hl_defs, expecting Integer");
    goto cleanup;
  }

  Dictionary rv = nvim__get_hl_defs(arg_1, arena, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_set_hl(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_hl", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;
  String arg_2;
  KeyDict_highlight arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_hl, expecting Integer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_set_hl, expecting String");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeDictionary) {
    memset(&arg_3, 0, sizeof(*&arg_3));
    if (!api_dict_to_keydict(&arg_3, KeyDict_highlight_get_field, args.items[2].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[2].type == kObjectTypeArray && args.items[2].data.array.size == 0) {
    memset(&arg_3, 0, sizeof(*&arg_3));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_set_hl, expecting Dict(highlight) *");
    goto cleanup;
  }

  nvim_set_hl(arg_1, arg_2, &arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_set_hl_ns(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_hl_ns", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_hl_ns, expecting Integer");
    goto cleanup;
  }

  nvim_set_hl_ns(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_set_hl_ns_fast(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_hl_ns_fast", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_hl_ns_fast, expecting Integer");
    goto cleanup;
  }

  nvim_set_hl_ns_fast(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_feedkeys(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_feedkeys", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  String arg_2;
  Boolean arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_feedkeys, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_feedkeys, expecting String");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeBoolean) {
    arg_3 = args.items[2].data.boolean;
  } else if (args.items[2].type == kObjectTypeInteger && args.items[2].data.integer >= 0) {
    arg_3 = (handle_T)args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_feedkeys, expecting Boolean");
    goto cleanup;
  }

  nvim_feedkeys(arg_1, arg_2, arg_3);


cleanup:
  return ret;
}

Object handle_nvim_input(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_input", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_input, expecting String");
    goto cleanup;
  }

  Integer rv = nvim_input(arg_1);

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_input_mouse(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_input_mouse", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  String arg_2;
  String arg_3;
  Integer arg_4;
  Integer arg_5;
  Integer arg_6;

  if (args.size != 6) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 6 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_input_mouse, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_input_mouse, expecting String");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeString) {
    arg_3 = args.items[2].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_input_mouse, expecting String");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeInteger) {
    arg_4 = args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_input_mouse, expecting Integer");
    goto cleanup;
  }

  if (args.items[4].type == kObjectTypeInteger) {
    arg_5 = args.items[4].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 5 when calling nvim_input_mouse, expecting Integer");
    goto cleanup;
  }

  if (args.items[5].type == kObjectTypeInteger) {
    arg_6 = args.items[5].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 6 when calling nvim_input_mouse, expecting Integer");
    goto cleanup;
  }

  nvim_input_mouse(arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_replace_termcodes(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_replace_termcodes", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Boolean arg_2;
  Boolean arg_3;
  Boolean arg_4;

  if (args.size != 4) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 4 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_replace_termcodes, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBoolean) {
    arg_2 = args.items[1].data.boolean;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_replace_termcodes, expecting Boolean");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeBoolean) {
    arg_3 = args.items[2].data.boolean;
  } else if (args.items[2].type == kObjectTypeInteger && args.items[2].data.integer >= 0) {
    arg_3 = (handle_T)args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_replace_termcodes, expecting Boolean");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeBoolean) {
    arg_4 = args.items[3].data.boolean;
  } else if (args.items[3].type == kObjectTypeInteger && args.items[3].data.integer >= 0) {
    arg_4 = (handle_T)args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_replace_termcodes, expecting Boolean");
    goto cleanup;
  }

  String rv = nvim_replace_termcodes(arg_1, arg_2, arg_3, arg_4);

  ret = STRING_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_exec_lua(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_exec_lua", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Array arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_exec_lua, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeArray) {
    arg_2 = args.items[1].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_exec_lua, expecting Array");
    goto cleanup;
  }

  Object rv = nvim_exec_lua(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_notify(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_notify", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Integer arg_2;
  Dictionary arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_notify, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_notify, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeDictionary) {
    arg_3 = args.items[2].data.dictionary;
  } else if (args.items[2].type == kObjectTypeArray && args.items[2].data.array.size == 0) {
    arg_3 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_notify, expecting Dictionary");
    goto cleanup;
  }

  Object rv = nvim_notify(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_strwidth(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_strwidth", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_strwidth, expecting String");
    goto cleanup;
  }

  Integer rv = nvim_strwidth(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_list_runtime_paths(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_list_runtime_paths", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  ArrayOf(String) rv = nvim_list_runtime_paths(error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim__runtime_inspect(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__runtime_inspect", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  Array rv = nvim__runtime_inspect();

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_runtime_file(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_runtime_file", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Boolean arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_runtime_file, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBoolean) {
    arg_2 = args.items[1].data.boolean;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_get_runtime_file, expecting Boolean");
    goto cleanup;
  }

  ArrayOf(String) rv = nvim_get_runtime_file(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim__get_lib_dir(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__get_lib_dir", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  String rv = nvim__get_lib_dir();

  ret = STRING_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim__get_runtime(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__get_runtime", channel_id);
#endif
  Object ret = NIL;
  Array arg_1;
  Boolean arg_2;
  KeyDict_runtime arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeArray) {
    arg_1 = args.items[0].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim__get_runtime, expecting Array");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBoolean) {
    arg_2 = args.items[1].data.boolean;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim__get_runtime, expecting Boolean");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeDictionary) {
    memset(&arg_3, 0, sizeof(*&arg_3));
    if (!api_dict_to_keydict(&arg_3, KeyDict_runtime_get_field, args.items[2].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[2].type == kObjectTypeArray && args.items[2].data.array.size == 0) {
    memset(&arg_3, 0, sizeof(*&arg_3));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim__get_runtime, expecting Dict(runtime) *");
    goto cleanup;
  }

  ArrayOf(String) rv = nvim__get_runtime(arg_1, arg_2, &arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_set_current_dir(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_current_dir", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_current_dir, expecting String");
    goto cleanup;
  }

  nvim_set_current_dir(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_get_current_line(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_current_line", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  String rv = nvim_get_current_line(error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = STRING_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_set_current_line(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_current_line", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_current_line, expecting String");
    goto cleanup;
  }

  if (textlock != 0) {
    api_set_error(error, kErrorTypeException, "%s", e_textlock);
    goto cleanup;
  }

  nvim_set_current_line(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_del_current_line(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_del_current_line", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  if (textlock != 0) {
    api_set_error(error, kErrorTypeException, "%s", e_textlock);
    goto cleanup;
  }

  nvim_del_current_line(error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_get_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_var", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_var, expecting String");
    goto cleanup;
  }

  Object rv = nvim_get_var(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_set_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_var", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Object arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_var, expecting String");
    goto cleanup;
  }

  arg_2 = args.items[1];

  nvim_set_var(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_del_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_del_var", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_del_var, expecting String");
    goto cleanup;
  }

  nvim_del_var(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_get_vvar(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_vvar", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_vvar, expecting String");
    goto cleanup;
  }

  Object rv = nvim_get_vvar(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_set_vvar(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_vvar", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Object arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_vvar, expecting String");
    goto cleanup;
  }

  arg_2 = args.items[1];

  nvim_set_vvar(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_echo(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_echo", channel_id);
#endif
  Object ret = NIL;
  Array arg_1;
  Boolean arg_2;
  Dictionary arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeArray) {
    arg_1 = args.items[0].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_echo, expecting Array");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBoolean) {
    arg_2 = args.items[1].data.boolean;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_echo, expecting Boolean");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeDictionary) {
    arg_3 = args.items[2].data.dictionary;
  } else if (args.items[2].type == kObjectTypeArray && args.items[2].data.array.size == 0) {
    arg_3 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_echo, expecting Dictionary");
    goto cleanup;
  }

  nvim_echo(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_out_write(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_out_write", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_out_write, expecting String");
    goto cleanup;
  }

  nvim_out_write(arg_1);


cleanup:
  return ret;
}

Object handle_nvim_err_write(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_err_write", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_err_write, expecting String");
    goto cleanup;
  }

  nvim_err_write(arg_1);


cleanup:
  return ret;
}

Object handle_nvim_err_writeln(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_err_writeln", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_err_writeln, expecting String");
    goto cleanup;
  }

  nvim_err_writeln(arg_1);


cleanup:
  return ret;
}

Object handle_nvim_list_bufs(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_list_bufs", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  ArrayOf(Buffer) rv = nvim_list_bufs();

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_current_buf(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_current_buf", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  Buffer rv = nvim_get_current_buf();

  ret = BUFFER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_set_current_buf(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_current_buf", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_current_buf, expecting Buffer");
    goto cleanup;
  }

  if (textlock != 0) {
    api_set_error(error, kErrorTypeException, "%s", e_textlock);
    goto cleanup;
  }

  nvim_set_current_buf(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_list_wins(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_list_wins", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  ArrayOf(Window) rv = nvim_list_wins();

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_current_win(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_current_win", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  Window rv = nvim_get_current_win();

  ret = WINDOW_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_set_current_win(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_current_win", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_current_win, expecting Window");
    goto cleanup;
  }

  if (textlock != 0) {
    api_set_error(error, kErrorTypeException, "%s", e_textlock);
    goto cleanup;
  }

  nvim_set_current_win(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_create_buf(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_create_buf", channel_id);
#endif
  Object ret = NIL;
  Boolean arg_1;
  Boolean arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBoolean) {
    arg_1 = args.items[0].data.boolean;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_create_buf, expecting Boolean");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBoolean) {
    arg_2 = args.items[1].data.boolean;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_create_buf, expecting Boolean");
    goto cleanup;
  }

  Buffer rv = nvim_create_buf(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = BUFFER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_open_term(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_open_term", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Dictionary arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_open_term, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeDictionary) {
    arg_2 = args.items[1].data.dictionary;
  } else if (args.items[1].type == kObjectTypeArray && args.items[1].data.array.size == 0) {
    arg_2 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_open_term, expecting DictionaryOf(LuaRef)");
    goto cleanup;
  }

  Integer rv = nvim_open_term(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_chan_send(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_chan_send", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_chan_send, expecting Integer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_chan_send, expecting String");
    goto cleanup;
  }

  nvim_chan_send(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_list_tabpages(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_list_tabpages", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  ArrayOf(Tabpage) rv = nvim_list_tabpages();

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_current_tabpage(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_current_tabpage", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  Tabpage rv = nvim_get_current_tabpage();

  ret = TABPAGE_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_set_current_tabpage(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_current_tabpage", channel_id);
#endif
  Object ret = NIL;
  Tabpage arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeTabpage && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_current_tabpage, expecting Tabpage");
    goto cleanup;
  }

  if (textlock != 0) {
    api_set_error(error, kErrorTypeException, "%s", e_textlock);
    goto cleanup;
  }

  nvim_set_current_tabpage(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_paste(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_paste", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Boolean arg_2;
  Integer arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_paste, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBoolean) {
    arg_2 = args.items[1].data.boolean;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_paste, expecting Boolean");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_paste, expecting Integer");
    goto cleanup;
  }

  if (textlock != 0) {
    api_set_error(error, kErrorTypeException, "%s", e_textlock);
    goto cleanup;
  }

  Boolean rv = nvim_paste(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = BOOLEAN_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_put(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_put", channel_id);
#endif
  Object ret = NIL;
  Array arg_1;
  String arg_2;
  Boolean arg_3;
  Boolean arg_4;

  if (args.size != 4) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 4 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeArray) {
    arg_1 = args.items[0].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_put, expecting ArrayOf(String)");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_put, expecting String");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeBoolean) {
    arg_3 = args.items[2].data.boolean;
  } else if (args.items[2].type == kObjectTypeInteger && args.items[2].data.integer >= 0) {
    arg_3 = (handle_T)args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_put, expecting Boolean");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeBoolean) {
    arg_4 = args.items[3].data.boolean;
  } else if (args.items[3].type == kObjectTypeInteger && args.items[3].data.integer >= 0) {
    arg_4 = (handle_T)args.items[3].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_put, expecting Boolean");
    goto cleanup;
  }

  if (textlock != 0) {
    api_set_error(error, kErrorTypeException, "%s", e_textlock);
    goto cleanup;
  }

  nvim_put(arg_1, arg_2, arg_3, arg_4, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_subscribe(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_subscribe", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_subscribe, expecting String");
    goto cleanup;
  }

  nvim_subscribe(channel_id, arg_1);


cleanup:
  return ret;
}

Object handle_nvim_unsubscribe(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_unsubscribe", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_unsubscribe, expecting String");
    goto cleanup;
  }

  nvim_unsubscribe(channel_id, arg_1);


cleanup:
  return ret;
}

Object handle_nvim_get_color_by_name(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_color_by_name", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_color_by_name, expecting String");
    goto cleanup;
  }

  Integer rv = nvim_get_color_by_name(arg_1);

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_color_map(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_color_map", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  Dictionary rv = nvim_get_color_map();

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_context(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_context", channel_id);
#endif
  Object ret = NIL;
  KeyDict_context arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeDictionary) {
    memset(&arg_1, 0, sizeof(*&arg_1));
    if (!api_dict_to_keydict(&arg_1, KeyDict_context_get_field, args.items[0].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[0].type == kObjectTypeArray && args.items[0].data.array.size == 0) {
    memset(&arg_1, 0, sizeof(*&arg_1));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_context, expecting Dict(context) *");
    goto cleanup;
  }

  Dictionary rv = nvim_get_context(&arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_load_context(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_load_context", channel_id);
#endif
  Object ret = NIL;
  Dictionary arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeDictionary) {
    arg_1 = args.items[0].data.dictionary;
  } else if (args.items[0].type == kObjectTypeArray && args.items[0].data.array.size == 0) {
    arg_1 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_load_context, expecting Dictionary");
    goto cleanup;
  }

  Object rv = nvim_load_context(arg_1);

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_mode(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_mode", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  Dictionary rv = nvim_get_mode();

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_keymap(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_keymap", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_keymap, expecting String");
    goto cleanup;
  }

  ArrayOf(Dictionary) rv = nvim_get_keymap(arg_1);

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_set_keymap(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_keymap", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  String arg_2;
  String arg_3;
  KeyDict_keymap arg_4;

  if (args.size != 4) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 4 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_keymap, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_set_keymap, expecting String");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeString) {
    arg_3 = args.items[2].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_set_keymap, expecting String");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeDictionary) {
    memset(&arg_4, 0, sizeof(*&arg_4));
    if (!api_dict_to_keydict(&arg_4, KeyDict_keymap_get_field, args.items[3].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[3].type == kObjectTypeArray && args.items[3].data.array.size == 0) {
    memset(&arg_4, 0, sizeof(*&arg_4));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_set_keymap, expecting Dict(keymap) *");
    goto cleanup;
  }

  nvim_set_keymap(channel_id, arg_1, arg_2, arg_3, &arg_4, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_del_keymap(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_del_keymap", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_del_keymap, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_del_keymap, expecting String");
    goto cleanup;
  }

  nvim_del_keymap(channel_id, arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_get_api_info(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_api_info", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  Array rv = nvim_get_api_info(channel_id, arena);

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_set_client_info(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_set_client_info", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Dictionary arg_2;
  String arg_3;
  Dictionary arg_4;
  Dictionary arg_5;

  if (args.size != 5) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 5 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_set_client_info, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeDictionary) {
    arg_2 = args.items[1].data.dictionary;
  } else if (args.items[1].type == kObjectTypeArray && args.items[1].data.array.size == 0) {
    arg_2 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_set_client_info, expecting Dictionary");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeString) {
    arg_3 = args.items[2].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_set_client_info, expecting String");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeDictionary) {
    arg_4 = args.items[3].data.dictionary;
  } else if (args.items[3].type == kObjectTypeArray && args.items[3].data.array.size == 0) {
    arg_4 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_set_client_info, expecting Dictionary");
    goto cleanup;
  }

  if (args.items[4].type == kObjectTypeDictionary) {
    arg_5 = args.items[4].data.dictionary;
  } else if (args.items[4].type == kObjectTypeArray && args.items[4].data.array.size == 0) {
    arg_5 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 5 when calling nvim_set_client_info, expecting Dictionary");
    goto cleanup;
  }

  nvim_set_client_info(channel_id, arg_1, arg_2, arg_3, arg_4, arg_5, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_get_chan_info(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_chan_info", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_chan_info, expecting Integer");
    goto cleanup;
  }

  Dictionary rv = nvim_get_chan_info(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_list_chans(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_list_chans", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  Array rv = nvim_list_chans();

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_call_atomic(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_call_atomic", channel_id);
#endif
  Object ret = NIL;
  Array arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeArray) {
    arg_1 = args.items[0].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_call_atomic, expecting Array");
    goto cleanup;
  }

  Array rv = nvim_call_atomic(channel_id, arg_1, arena, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim__id(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__id", channel_id);
#endif
  Object ret = NIL;
  Object arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  arg_1 = args.items[0];

  Object rv = nvim__id(arg_1);

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim__id_array(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__id_array", channel_id);
#endif
  Object ret = NIL;
  Array arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeArray) {
    arg_1 = args.items[0].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim__id_array, expecting Array");
    goto cleanup;
  }

  Array rv = nvim__id_array(arg_1);

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim__id_dictionary(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__id_dictionary", channel_id);
#endif
  Object ret = NIL;
  Dictionary arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeDictionary) {
    arg_1 = args.items[0].data.dictionary;
  } else if (args.items[0].type == kObjectTypeArray && args.items[0].data.array.size == 0) {
    arg_1 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim__id_dictionary, expecting Dictionary");
    goto cleanup;
  }

  Dictionary rv = nvim__id_dictionary(arg_1);

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim__id_float(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__id_float", channel_id);
#endif
  Object ret = NIL;
  Float arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeFloat) {
    arg_1 = args.items[0].data.floating;
  } else if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = (Float)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim__id_float, expecting Float");
    goto cleanup;
  }

  Float rv = nvim__id_float(arg_1);

  ret = FLOAT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim__stats(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__stats", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  Dictionary rv = nvim__stats();

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_list_uis(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_list_uis", channel_id);
#endif
  Object ret = NIL;

  if (args.size != 0) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 0 but got %zu", args.size);
    goto cleanup;
  }

  Array rv = nvim_list_uis();

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_proc_children(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_proc_children", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_proc_children, expecting Integer");
    goto cleanup;
  }

  Array rv = nvim_get_proc_children(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_proc(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_proc", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_proc, expecting Integer");
    goto cleanup;
  }

  Object rv = nvim_get_proc(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_select_popupmenu_item(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_select_popupmenu_item", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;
  Boolean arg_2;
  Boolean arg_3;
  Dictionary arg_4;

  if (args.size != 4) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 4 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_select_popupmenu_item, expecting Integer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBoolean) {
    arg_2 = args.items[1].data.boolean;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_select_popupmenu_item, expecting Boolean");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeBoolean) {
    arg_3 = args.items[2].data.boolean;
  } else if (args.items[2].type == kObjectTypeInteger && args.items[2].data.integer >= 0) {
    arg_3 = (handle_T)args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_select_popupmenu_item, expecting Boolean");
    goto cleanup;
  }

  if (args.items[3].type == kObjectTypeDictionary) {
    arg_4 = args.items[3].data.dictionary;
  } else if (args.items[3].type == kObjectTypeArray && args.items[3].data.array.size == 0) {
    arg_4 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 4 when calling nvim_select_popupmenu_item, expecting Dictionary");
    goto cleanup;
  }

  nvim_select_popupmenu_item(arg_1, arg_2, arg_3, arg_4, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim__inspect_cell(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__inspect_cell", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;
  Integer arg_2;
  Integer arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim__inspect_cell, expecting Integer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim__inspect_cell, expecting Integer");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeInteger) {
    arg_3 = args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim__inspect_cell, expecting Integer");
    goto cleanup;
  }

  Array rv = nvim__inspect_cell(arg_1, arg_2, arg_3, arena, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim__screenshot(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__screenshot", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim__screenshot, expecting String");
    goto cleanup;
  }

  nvim__screenshot(arg_1);


cleanup:
  return ret;
}

Object handle_nvim__unpack(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim__unpack", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim__unpack, expecting String");
    goto cleanup;
  }

  Object rv = nvim__unpack(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_del_mark(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_del_mark", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_del_mark, expecting String");
    goto cleanup;
  }

  Boolean rv = nvim_del_mark(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = BOOLEAN_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_get_mark(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_get_mark", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Dictionary arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_get_mark, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeDictionary) {
    arg_2 = args.items[1].data.dictionary;
  } else if (args.items[1].type == kObjectTypeArray && args.items[1].data.array.size == 0) {
    arg_2 = (Dictionary)ARRAY_DICT_INIT;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_get_mark, expecting Dictionary");
    goto cleanup;
  }

  Array rv = nvim_get_mark(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_eval_statusline(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_eval_statusline", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  KeyDict_eval_statusline arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_eval_statusline, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeDictionary) {
    memset(&arg_2, 0, sizeof(*&arg_2));
    if (!api_dict_to_keydict(&arg_2, KeyDict_eval_statusline_get_field, args.items[1].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[1].type == kObjectTypeArray && args.items[1].data.array.size == 0) {
    memset(&arg_2, 0, sizeof(*&arg_2));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_eval_statusline, expecting Dict(eval_statusline) *");
    goto cleanup;
  }

  Dictionary rv = nvim_eval_statusline(arg_1, &arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_error_event(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_error_event", channel_id);
#endif
  Object ret = NIL;
  Integer arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeInteger) {
    arg_1 = args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_error_event, expecting Integer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_error_event, expecting String");
    goto cleanup;
  }

  nvim_error_event(channel_id, arg_1, arg_2);


cleanup:
  return ret;
}

Object handle_nvim_exec(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_exec", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Boolean arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_exec, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBoolean) {
    arg_2 = args.items[1].data.boolean;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_exec, expecting Boolean");
    goto cleanup;
  }

  String rv = nvim_exec(channel_id, arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = STRING_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_command(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_command", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_command, expecting String");
    goto cleanup;
  }

  nvim_command(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_eval(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_eval", channel_id);
#endif
  Object ret = NIL;
  String arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_eval, expecting String");
    goto cleanup;
  }

  Object rv = nvim_eval(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_call_function(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_call_function", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  Array arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_call_function, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeArray) {
    arg_2 = args.items[1].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_call_function, expecting Array");
    goto cleanup;
  }

  Object rv = nvim_call_function(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_call_dict_function(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_call_dict_function", channel_id);
#endif
  Object ret = NIL;
  Object arg_1;
  String arg_2;
  Array arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  arg_1 = args.items[0];

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_call_dict_function, expecting String");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeArray) {
    arg_3 = args.items[2].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_call_dict_function, expecting Array");
    goto cleanup;
  }

  Object rv = nvim_call_dict_function(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_parse_expression(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_parse_expression", channel_id);
#endif
  Object ret = NIL;
  String arg_1;
  String arg_2;
  Boolean arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeString) {
    arg_1 = args.items[0].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_parse_expression, expecting String");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_parse_expression, expecting String");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeBoolean) {
    arg_3 = args.items[2].data.boolean;
  } else if (args.items[2].type == kObjectTypeInteger && args.items[2].data.integer >= 0) {
    arg_3 = (handle_T)args.items[2].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_parse_expression, expecting Boolean");
    goto cleanup;
  }

  Dictionary rv = nvim_parse_expression(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_open_win(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_open_win", channel_id);
#endif
  Object ret = NIL;
  Buffer arg_1;
  Boolean arg_2;
  KeyDict_float_config arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeBuffer && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_open_win, expecting Buffer");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBoolean) {
    arg_2 = args.items[1].data.boolean;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_open_win, expecting Boolean");
    goto cleanup;
  }

  if (args.items[2].type == kObjectTypeDictionary) {
    memset(&arg_3, 0, sizeof(*&arg_3));
    if (!api_dict_to_keydict(&arg_3, KeyDict_float_config_get_field, args.items[2].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[2].type == kObjectTypeArray && args.items[2].data.array.size == 0) {
    memset(&arg_3, 0, sizeof(*&arg_3));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 3 when calling nvim_open_win, expecting Dict(float_config) *");
    goto cleanup;
  }

  if (textlock != 0) {
    api_set_error(error, kErrorTypeException, "%s", e_textlock);
    goto cleanup;
  }

  Window rv = nvim_open_win(arg_1, arg_2, &arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = WINDOW_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_win_set_config(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_set_config", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  KeyDict_float_config arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_set_config, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeDictionary) {
    memset(&arg_2, 0, sizeof(*&arg_2));
    if (!api_dict_to_keydict(&arg_2, KeyDict_float_config_get_field, args.items[1].data.dictionary, error)) {
      goto cleanup;
    }
  } else if (args.items[1].type == kObjectTypeArray && args.items[1].data.array.size == 0) {
    memset(&arg_2, 0, sizeof(*&arg_2));
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_win_set_config, expecting Dict(float_config) *");
    goto cleanup;
  }

  nvim_win_set_config(arg_1, &arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_win_get_config(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_get_config", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_get_config, expecting Window");
    goto cleanup;
  }

  Dictionary rv = nvim_win_get_config(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = DICTIONARY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_win_get_buf(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_get_buf", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_get_buf, expecting Window");
    goto cleanup;
  }

  Buffer rv = nvim_win_get_buf(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = BUFFER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_win_set_buf(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_set_buf", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  Buffer arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_set_buf, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBuffer && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_win_set_buf, expecting Buffer");
    goto cleanup;
  }

  if (textlock != 0) {
    api_set_error(error, kErrorTypeException, "%s", e_textlock);
    goto cleanup;
  }

  nvim_win_set_buf(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_win_get_cursor(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_get_cursor", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_get_cursor, expecting Window");
    goto cleanup;
  }

  ArrayOf(Integer, 2) rv = nvim_win_get_cursor(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_win_set_cursor(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_set_cursor", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  Array arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_set_cursor, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeArray) {
    arg_2 = args.items[1].data.array;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_win_set_cursor, expecting ArrayOf(Integer, 2)");
    goto cleanup;
  }

  nvim_win_set_cursor(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_win_get_height(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_get_height", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_get_height, expecting Window");
    goto cleanup;
  }

  Integer rv = nvim_win_get_height(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_win_set_height(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_set_height", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  Integer arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_set_height, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_win_set_height, expecting Integer");
    goto cleanup;
  }

  nvim_win_set_height(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_win_get_width(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_get_width", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_get_width, expecting Window");
    goto cleanup;
  }

  Integer rv = nvim_win_get_width(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_win_set_width(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_set_width", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  Integer arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_set_width, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_win_set_width, expecting Integer");
    goto cleanup;
  }

  nvim_win_set_width(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_win_get_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_get_var", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_get_var, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_win_get_var, expecting String");
    goto cleanup;
  }

  Object rv = nvim_win_get_var(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = OBJECT_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_win_set_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_set_var", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  String arg_2;
  Object arg_3;

  if (args.size != 3) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 3 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_set_var, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_win_set_var, expecting String");
    goto cleanup;
  }

  arg_3 = args.items[2];

  nvim_win_set_var(arg_1, arg_2, arg_3, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_win_del_var(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_del_var", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  String arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_del_var, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeString) {
    arg_2 = args.items[1].data.string;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_win_del_var, expecting String");
    goto cleanup;
  }

  nvim_win_del_var(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_win_get_position(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_get_position", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_get_position, expecting Window");
    goto cleanup;
  }

  ArrayOf(Integer, 2) rv = nvim_win_get_position(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = ARRAY_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_win_get_tabpage(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_get_tabpage", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_get_tabpage, expecting Window");
    goto cleanup;
  }

  Tabpage rv = nvim_win_get_tabpage(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = TABPAGE_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_win_get_number(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_get_number", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_get_number, expecting Window");
    goto cleanup;
  }

  Integer rv = nvim_win_get_number(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }

  ret = INTEGER_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_win_is_valid(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_is_valid", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_is_valid, expecting Window");
    goto cleanup;
  }

  Boolean rv = nvim_win_is_valid(arg_1);

  ret = BOOLEAN_OBJ(rv);

cleanup:
  return ret;
}

Object handle_nvim_win_hide(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_hide", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;

  if (args.size != 1) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 1 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_hide, expecting Window");
    goto cleanup;
  }

  if (textlock != 0) {
    api_set_error(error, kErrorTypeException, "%s", e_textlock);
    goto cleanup;
  }

  nvim_win_hide(arg_1, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_win_close(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_close", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  Boolean arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_close, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeBoolean) {
    arg_2 = args.items[1].data.boolean;
  } else if (args.items[1].type == kObjectTypeInteger && args.items[1].data.integer >= 0) {
    arg_2 = (handle_T)args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_win_close, expecting Boolean");
    goto cleanup;
  }

  if (textlock != 0) {
    api_set_error(error, kErrorTypeException, "%s", e_textlock);
    goto cleanup;
  }

  nvim_win_close(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

Object handle_nvim_win_set_hl_ns(uint64_t channel_id, Array args, Arena* arena, Error *error)
{
#if MIN_LOG_LEVEL <= LOGLVL_DBG
  logmsg(LOGLVL_DBG, "RPC: ", NULL, -1, true, "ch %" PRIu64 ": invoke nvim_win_set_hl_ns", channel_id);
#endif
  Object ret = NIL;
  Window arg_1;
  Integer arg_2;

  if (args.size != 2) {
    api_set_error(error, kErrorTypeException, 
      "Wrong number of arguments: expecting 2 but got %zu", args.size);
    goto cleanup;
  }

  if (args.items[0].type == kObjectTypeWindow && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else if (args.items[0].type == kObjectTypeInteger && args.items[0].data.integer >= 0) {
    arg_1 = (handle_T)args.items[0].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 1 when calling nvim_win_set_hl_ns, expecting Window");
    goto cleanup;
  }

  if (args.items[1].type == kObjectTypeInteger) {
    arg_2 = args.items[1].data.integer;
  } else {
    api_set_error(error, kErrorTypeException, 
          "Wrong type for argument 2 when calling nvim_win_set_hl_ns, expecting Integer");
    goto cleanup;
  }

  nvim_win_set_hl_ns(arg_1, arg_2, error);

  if (ERROR_SET(error)) {
    goto cleanup;
  }


cleanup:
  return ret;
}

const MsgpackRpcRequestHandler method_handlers[] = {
  { .name = "redraw", .fn = handle_ui_client_redraw, .fast = true, .arena_return = false},
  { .name = "nvim__id", .fn = handle_nvim__id, .fast = false, .arena_return = false},
  { .name = "nvim_cmd", .fn = handle_nvim_cmd, .fast = false, .arena_return = false},
  { .name = "nvim_put", .fn = handle_nvim_put, .fast = false, .arena_return = false},
  { .name = "vim_eval", .fn = handle_nvim_eval, .fast = false, .arena_return = false},
  { .name = "ui_attach", .fn = handle_ui_attach, .fast = false, .arena_return = false},
  { .name = "ui_detach", .fn = handle_nvim_ui_detach, .fast = false, .arena_return = false},
  { .name = "nvim_echo", .fn = handle_nvim_echo, .fast = false, .arena_return = false},
  { .name = "vim_input", .fn = handle_nvim_input, .fast = true, .arena_return = false},
  { .name = "nvim_eval", .fn = handle_nvim_eval, .fast = false, .arena_return = false},
  { .name = "nvim_exec", .fn = handle_nvim_exec, .fast = false, .arena_return = false},
  { .name = "nvim_input", .fn = handle_nvim_input, .fast = true, .arena_return = false},
  { .name = "nvim_paste", .fn = handle_nvim_paste, .fast = false, .arena_return = false},
  { .name = "nvim_set_hl", .fn = handle_nvim_set_hl, .fast = false, .arena_return = false},
  { .name = "vim_del_var", .fn = handle_vim_del_var, .fast = false, .arena_return = false},
  { .name = "vim_command", .fn = handle_nvim_command, .fast = false, .arena_return = false},
  { .name = "nvim_notify", .fn = handle_nvim_notify, .fast = false, .arena_return = false},
  { .name = "nvim__stats", .fn = handle_nvim__stats, .fast = false, .arena_return = false},
  { .name = "vim_get_var", .fn = handle_nvim_get_var, .fast = false, .arena_return = false},
  { .name = "vim_set_var", .fn = handle_vim_set_var, .fast = false, .arena_return = false},
  { .name = "nvim__unpack", .fn = handle_nvim__unpack, .fast = true, .arena_return = false},
  { .name = "nvim_command", .fn = handle_nvim_command, .fast = false, .arena_return = false},
  { .name = "nvim_del_var", .fn = handle_nvim_del_var, .fast = false, .arena_return = false},
  { .name = "vim_feedkeys", .fn = handle_nvim_feedkeys, .fast = false, .arena_return = false},
  { .name = "vim_get_vvar", .fn = handle_nvim_get_vvar, .fast = false, .arena_return = false},
  { .name = "nvim_get_var", .fn = handle_nvim_get_var, .fast = false, .arena_return = false},
  { .name = "nvim_set_var", .fn = handle_nvim_set_var, .fast = false, .arena_return = false},
  { .name = "vim_strwidth", .fn = handle_nvim_strwidth, .fast = false, .arena_return = false},
  { .name = "nvim_exec_lua", .fn = handle_nvim_exec_lua, .fast = false, .arena_return = false},
  { .name = "nvim_list_uis", .fn = handle_nvim_list_uis, .fast = false, .arena_return = false},
  { .name = "nvim_open_win", .fn = handle_nvim_open_win, .fast = false, .arena_return = false},
  { .name = "nvim_win_hide", .fn = handle_nvim_win_hide, .fast = false, .arena_return = false},
  { .name = "nvim_strwidth", .fn = handle_nvim_strwidth, .fast = false, .arena_return = false},
  { .name = "nvim_feedkeys", .fn = handle_nvim_feedkeys, .fast = false, .arena_return = false},
  { .name = "nvim_get_mode", .fn = handle_nvim_get_mode, .fast = true, .arena_return = false},
  { .name = "nvim_del_mark", .fn = handle_nvim_del_mark, .fast = false, .arena_return = false},
  { .name = "nvim_get_mark", .fn = handle_nvim_get_mark, .fast = false, .arena_return = false},
  { .name = "nvim_get_proc", .fn = handle_nvim_get_proc, .fast = false, .arena_return = false},
  { .name = "vim_err_write", .fn = handle_nvim_err_write, .fast = false, .arena_return = false},
  { .name = "vim_out_write", .fn = handle_nvim_out_write, .fast = false, .arena_return = false},
  { .name = "vim_subscribe", .fn = handle_nvim_subscribe, .fast = false, .arena_return = false},
  { .name = "ui_try_resize", .fn = handle_nvim_ui_try_resize, .fast = false, .arena_return = false},
  { .name = "buffer_insert", .fn = handle_buffer_insert, .fast = false, .arena_return = false},
  { .name = "nvim_get_vvar", .fn = handle_nvim_get_vvar, .fast = false, .arena_return = false},
  { .name = "nvim_set_vvar", .fn = handle_nvim_set_vvar, .fast = false, .arena_return = false},
  { .name = "nvim__id_array", .fn = handle_nvim__id_array, .fast = false, .arena_return = false},
  { .name = "nvim__id_float", .fn = handle_nvim__id_float, .fast = false, .arena_return = false},
  { .name = "nvim_chan_send", .fn = handle_nvim_chan_send, .fast = false, .arena_return = false},
  { .name = "nvim_err_write", .fn = handle_nvim_err_write, .fast = false, .arena_return = false},
  { .name = "vim_get_option", .fn = handle_nvim_get_option, .fast = false, .arena_return = false},
  { .name = "vim_set_option", .fn = handle_nvim_set_option, .fast = false, .arena_return = false},
  { .name = "nvim_list_bufs", .fn = handle_nvim_list_bufs, .fast = false, .arena_return = false},
  { .name = "nvim_list_wins", .fn = handle_nvim_list_wins, .fast = false, .arena_return = false},
  { .name = "nvim_out_write", .fn = handle_nvim_out_write, .fast = false, .arena_return = false},
  { .name = "nvim_open_term", .fn = handle_nvim_open_term, .fast = false, .arena_return = false},
  { .name = "nvim_parse_cmd", .fn = handle_nvim_parse_cmd, .fast = true, .arena_return = false},
  { .name = "buffer_get_var", .fn = handle_nvim_buf_get_var, .fast = false, .arena_return = false},
  { .name = "buffer_set_var", .fn = handle_buffer_set_var, .fast = false, .arena_return = false},
  { .name = "buffer_del_var", .fn = handle_buffer_del_var, .fast = false, .arena_return = false},
  { .name = "nvim_set_hl_ns", .fn = handle_nvim_set_hl_ns, .fast = false, .arena_return = false},
  { .name = "nvim_subscribe", .fn = handle_nvim_subscribe, .fast = false, .arena_return = false},
  { .name = "nvim_ui_attach", .fn = handle_nvim_ui_attach, .fast = false, .arena_return = false},
  { .name = "nvim_ui_detach", .fn = handle_nvim_ui_detach, .fast = false, .arena_return = false},
  { .name = "nvim_win_close", .fn = handle_nvim_win_close, .fast = false, .arena_return = false},
  { .name = "window_set_var", .fn = handle_window_set_var, .fast = false, .arena_return = false},
  { .name = "window_del_var", .fn = handle_window_del_var, .fast = false, .arena_return = false},
  { .name = "window_get_var", .fn = handle_nvim_win_get_var, .fast = false, .arena_return = false},
  { .name = "vim_get_buffers", .fn = handle_nvim_list_bufs, .fast = false, .arena_return = false},
  { .name = "vim_get_windows", .fn = handle_nvim_list_wins, .fast = false, .arena_return = false},
  { .name = "tabpage_get_var", .fn = handle_nvim_tabpage_get_var, .fast = false, .arena_return = false},
  { .name = "tabpage_set_var", .fn = handle_tabpage_set_var, .fast = false, .arena_return = false},
  { .name = "tabpage_del_var", .fn = handle_tabpage_del_var, .fast = false, .arena_return = false},
  { .name = "buffer_del_line", .fn = handle_buffer_del_line, .fast = false, .arena_return = false},
  { .name = "nvim_create_buf", .fn = handle_nvim_create_buf, .fast = false, .arena_return = false},
  { .name = "nvim_buf_attach", .fn = handle_nvim_buf_attach, .fast = false, .arena_return = false},
  { .name = "nvim_buf_detach", .fn = handle_nvim_buf_detach, .fast = false, .arena_return = false},
  { .name = "nvim_buf_delete", .fn = handle_nvim_buf_delete, .fast = false, .arena_return = false},
  { .name = "buffer_get_mark", .fn = handle_nvim_buf_get_mark, .fast = false, .arena_return = false},
  { .name = "buffer_get_name", .fn = handle_nvim_buf_get_name, .fast = false, .arena_return = true},
  { .name = "buffer_get_line", .fn = handle_buffer_get_line, .fast = false, .arena_return = false},
  { .name = "buffer_is_valid", .fn = handle_nvim_buf_is_valid, .fast = false, .arena_return = false},
  { .name = "window_is_valid", .fn = handle_nvim_win_is_valid, .fast = false, .arena_return = false},
  { .name = "nvim_del_keymap", .fn = handle_nvim_del_keymap, .fast = false, .arena_return = false},
  { .name = "nvim_list_chans", .fn = handle_nvim_list_chans, .fast = false, .arena_return = false},
  { .name = "buffer_set_name", .fn = handle_nvim_buf_set_name, .fast = false, .arena_return = false},
  { .name = "buffer_set_line", .fn = handle_buffer_set_line, .fast = false, .arena_return = false},
  { .name = "nvim_set_option", .fn = handle_nvim_set_option, .fast = false, .arena_return = false},
  { .name = "nvim_get_option", .fn = handle_nvim_get_option, .fast = false, .arena_return = false},
  { .name = "nvim_get_keymap", .fn = handle_nvim_get_keymap, .fast = false, .arena_return = false},
  { .name = "nvim_set_keymap", .fn = handle_nvim_set_keymap, .fast = false, .arena_return = false},
  { .name = "vim_unsubscribe", .fn = handle_nvim_unsubscribe, .fast = false, .arena_return = false},
  { .name = "nvim__buf_stats", .fn = handle_nvim__buf_stats, .fast = false, .arena_return = false},
  { .name = "buffer_get_lines", .fn = handle_nvim_buf_get_lines, .fast = false, .arena_return = false},
  { .name = "buffer_set_lines", .fn = handle_nvim_buf_set_lines, .fast = false, .arena_return = false},
  { .name = "window_get_width", .fn = handle_nvim_win_get_width, .fast = false, .arena_return = false},
  { .name = "window_set_width", .fn = handle_nvim_win_set_width, .fast = false, .arena_return = false},
  { .name = "nvim_call_atomic", .fn = handle_nvim_call_atomic, .fast = false, .arena_return = true},
  { .name = "nvim_del_autocmd", .fn = handle_nvim_del_autocmd, .fast = false, .arena_return = false},
  { .name = "nvim_get_context", .fn = handle_nvim_get_context, .fast = false, .arena_return = false},
  { .name = "tabpage_is_valid", .fn = handle_nvim_tabpage_is_valid, .fast = false, .arena_return = false},
  { .name = "nvim_win_get_buf", .fn = handle_nvim_win_get_buf, .fast = false, .arena_return = false},
  { .name = "nvim_win_set_buf", .fn = handle_nvim_win_set_buf, .fast = false, .arena_return = false},
  { .name = "nvim_win_get_var", .fn = handle_nvim_win_get_var, .fast = false, .arena_return = false},
  { .name = "nvim_win_set_var", .fn = handle_nvim_win_set_var, .fast = false, .arena_return = false},
  { .name = "nvim_win_del_var", .fn = handle_nvim_win_del_var, .fast = false, .arena_return = false},
  { .name = "nvim_input_mouse", .fn = handle_nvim_input_mouse, .fast = true, .arena_return = false},
  { .name = "nvim_unsubscribe", .fn = handle_nvim_unsubscribe, .fast = false, .arena_return = false},
  { .name = "vim_report_error", .fn = handle_nvim_err_writeln, .fast = false, .arena_return = false},
  { .name = "nvim_err_writeln", .fn = handle_nvim_err_writeln, .fast = false, .arena_return = false},
  { .name = "nvim_error_event", .fn = handle_nvim_error_event, .fast = false, .arena_return = false},
  { .name = "nvim__screenshot", .fn = handle_nvim__screenshot, .fast = true, .arena_return = false},
  { .name = "vim_get_api_info", .fn = handle_nvim_get_api_info, .fast = true, .arena_return = true},
  { .name = "vim_get_tabpages", .fn = handle_nvim_list_tabpages, .fast = false, .arena_return = false},
  { .name = "nvim_buf_get_var", .fn = handle_nvim_buf_get_var, .fast = false, .arena_return = false},
  { .name = "nvim_buf_set_var", .fn = handle_nvim_buf_set_var, .fast = false, .arena_return = false},
  { .name = "nvim_buf_del_var", .fn = handle_nvim_buf_del_var, .fast = false, .arena_return = false},
  { .name = "nvim_execute_lua", .fn = handle_nvim_execute_lua, .fast = false, .arena_return = false},
  { .name = "nvim_get_hl_by_id", .fn = handle_nvim_get_hl_by_id, .fast = false, .arena_return = true},
  { .name = "nvim_buf_del_mark", .fn = handle_nvim_buf_del_mark, .fast = false, .arena_return = false},
  { .name = "nvim_buf_set_mark", .fn = handle_nvim_buf_set_mark, .fast = false, .arena_return = false},
  { .name = "nvim_buf_set_name", .fn = handle_nvim_buf_set_name, .fast = false, .arena_return = false},
  { .name = "nvim_buf_get_mark", .fn = handle_nvim_buf_get_mark, .fast = false, .arena_return = false},
  { .name = "nvim_buf_get_name", .fn = handle_nvim_buf_get_name, .fast = false, .arena_return = true},
  { .name = "buffer_get_number", .fn = handle_nvim_buf_get_number, .fast = false, .arena_return = false},
  { .name = "nvim__get_lib_dir", .fn = handle_nvim__get_lib_dir, .fast = false, .arena_return = false},
  { .name = "nvim_buf_set_text", .fn = handle_nvim_buf_set_text, .fast = false, .arena_return = false},
  { .name = "nvim__get_hl_defs", .fn = handle_nvim__get_hl_defs, .fast = false, .arena_return = true},
  { .name = "nvim_load_context", .fn = handle_nvim_load_context, .fast = false, .arena_return = false},
  { .name = "nvim_buf_get_text", .fn = handle_nvim_buf_get_text, .fast = false, .arena_return = false},
  { .name = "window_get_buffer", .fn = handle_nvim_win_get_buf, .fast = false, .arena_return = false},
  { .name = "window_get_height", .fn = handle_nvim_win_get_height, .fast = false, .arena_return = false},
  { .name = "window_set_height", .fn = handle_nvim_win_set_height, .fast = false, .arena_return = false},
  { .name = "buffer_get_option", .fn = handle_nvim_buf_get_option, .fast = false, .arena_return = false},
  { .name = "buffer_set_option", .fn = handle_nvim_buf_set_option, .fast = false, .arena_return = false},
  { .name = "vim_call_function", .fn = handle_nvim_call_function, .fast = false, .arena_return = false},
  { .name = "window_get_option", .fn = handle_nvim_win_get_option, .fast = false, .arena_return = false},
  { .name = "window_set_option", .fn = handle_nvim_win_set_option, .fast = false, .arena_return = false},
  { .name = "nvim__get_runtime", .fn = handle_nvim__get_runtime, .fast = true, .arena_return = false},
  { .name = "nvim_win_is_valid", .fn = handle_nvim_win_is_valid, .fast = false, .arena_return = false},
  { .name = "vim_name_to_color", .fn = handle_nvim_get_color_by_name, .fast = false, .arena_return = false},
  { .name = "nvim_buf_is_valid", .fn = handle_nvim_buf_is_valid, .fast = false, .arena_return = false},
  { .name = "nvim_get_autocmds", .fn = handle_nvim_get_autocmds, .fast = false, .arena_return = false},
  { .name = "vim_get_color_map", .fn = handle_nvim_get_color_map, .fast = false, .arena_return = false},
  { .name = "nvim_get_commands", .fn = handle_nvim_get_commands, .fast = false, .arena_return = false},
  { .name = "nvim_get_api_info", .fn = handle_nvim_get_api_info, .fast = true, .arena_return = true},
  { .name = "window_get_cursor", .fn = handle_nvim_win_get_cursor, .fast = false, .arena_return = false},
  { .name = "window_set_cursor", .fn = handle_nvim_win_set_cursor, .fast = false, .arena_return = false},
  { .name = "buffer_line_count", .fn = handle_nvim_buf_line_count, .fast = false, .arena_return = false},
  { .name = "nvim_get_chan_info", .fn = handle_nvim_get_chan_info, .fast = false, .arena_return = false},
  { .name = "nvim__inspect_cell", .fn = handle_nvim__inspect_cell, .fast = false, .arena_return = true},
  { .name = "window_get_tabpage", .fn = handle_nvim_win_get_tabpage, .fast = false, .arena_return = false},
  { .name = "nvim_call_function", .fn = handle_nvim_call_function, .fast = false, .arena_return = false},
  { .name = "nvim_ui_try_resize", .fn = handle_nvim_ui_try_resize, .fast = false, .arena_return = false},
  { .name = "nvim_win_set_hl_ns", .fn = handle_nvim_win_set_hl_ns, .fast = false, .arena_return = false},
  { .name = "tabpage_get_window", .fn = handle_nvim_tabpage_get_win, .fast = false, .arena_return = false},
  { .name = "nvim_buf_get_lines", .fn = handle_nvim_buf_get_lines, .fast = false, .arena_return = false},
  { .name = "nvim_buf_set_lines", .fn = handle_nvim_buf_set_lines, .fast = false, .arena_return = false},
  { .name = "nvim_exec_autocmds", .fn = handle_nvim_exec_autocmds, .fast = false, .arena_return = false},
  { .name = "nvim_buf_is_loaded", .fn = handle_nvim_buf_is_loaded, .fast = false, .arena_return = false},
  { .name = "nvim_ui_set_option", .fn = handle_nvim_ui_set_option, .fast = false, .arena_return = false},
  { .name = "nvim_list_tabpages", .fn = handle_nvim_list_tabpages, .fast = false, .arena_return = false},
  { .name = "nvim_get_color_map", .fn = handle_nvim_get_color_map, .fast = false, .arena_return = false},
  { .name = "vim_command_output", .fn = handle_nvim_command_output, .fast = false, .arena_return = false},
  { .name = "nvim_win_get_width", .fn = handle_nvim_win_get_width, .fast = false, .arena_return = false},
  { .name = "nvim_win_set_width", .fn = handle_nvim_win_set_width, .fast = false, .arena_return = false},
  { .name = "nvim_get_hl_by_name", .fn = handle_nvim_get_hl_by_name, .fast = false, .arena_return = true},
  { .name = "nvim_set_hl_ns_fast", .fn = handle_nvim_set_hl_ns_fast, .fast = true, .arena_return = false},
  { .name = "nvim_buf_line_count", .fn = handle_nvim_buf_line_count, .fast = false, .arena_return = false},
  { .name = "nvim_buf_get_keymap", .fn = handle_nvim_buf_get_keymap, .fast = false, .arena_return = false},
  { .name = "nvim_buf_set_keymap", .fn = handle_nvim_buf_set_keymap, .fast = false, .arena_return = false},
  { .name = "nvim_buf_del_keymap", .fn = handle_nvim_buf_del_keymap, .fast = false, .arena_return = false},
  { .name = "nvim_win_get_height", .fn = handle_nvim_win_get_height, .fast = false, .arena_return = false},
  { .name = "nvim_win_set_height", .fn = handle_nvim_win_set_height, .fast = false, .arena_return = false},
  { .name = "nvim_buf_get_offset", .fn = handle_nvim_buf_get_offset, .fast = false, .arena_return = false},
  { .name = "nvim_create_augroup", .fn = handle_nvim_create_augroup, .fast = false, .arena_return = false},
  { .name = "window_get_position", .fn = handle_nvim_win_get_position, .fast = false, .arena_return = false},
  { .name = "tabpage_get_windows", .fn = handle_nvim_tabpage_list_wins, .fast = false, .arena_return = false},
  { .name = "nvim_clear_autocmds", .fn = handle_nvim_clear_autocmds, .fast = false, .arena_return = false},
  { .name = "nvim__id_dictionary", .fn = handle_nvim__id_dictionary, .fast = false, .arena_return = false},
  { .name = "nvim_win_set_config", .fn = handle_nvim_win_set_config, .fast = false, .arena_return = false},
  { .name = "nvim_win_get_config", .fn = handle_nvim_win_get_config, .fast = false, .arena_return = false},
  { .name = "nvim_buf_set_option", .fn = handle_nvim_buf_set_option, .fast = false, .arena_return = false},
  { .name = "nvim_win_get_option", .fn = handle_nvim_win_get_option, .fast = false, .arena_return = false},
  { .name = "nvim_win_set_option", .fn = handle_nvim_win_set_option, .fast = false, .arena_return = false},
  { .name = "nvim_get_namespaces", .fn = handle_nvim_get_namespaces, .fast = false, .arena_return = false},
  { .name = "nvim_buf_get_option", .fn = handle_nvim_buf_get_option, .fast = false, .arena_return = false},
  { .name = "nvim_create_autocmd", .fn = handle_nvim_create_autocmd, .fast = false, .arena_return = false},
  { .name = "nvim_command_output", .fn = handle_nvim_command_output, .fast = false, .arena_return = false},
  { .name = "nvim_win_get_cursor", .fn = handle_nvim_win_get_cursor, .fast = false, .arena_return = false},
  { .name = "nvim_win_set_cursor", .fn = handle_nvim_win_set_cursor, .fast = false, .arena_return = false},
  { .name = "nvim_win_get_number", .fn = handle_nvim_win_get_number, .fast = false, .arena_return = false},
  { .name = "nvim_buf_get_number", .fn = handle_nvim_buf_get_number, .fast = false, .arena_return = false},
  { .name = "nvim_buf_set_extmark", .fn = handle_nvim_buf_set_extmark, .fast = false, .arena_return = false},
  { .name = "nvim_buf_del_extmark", .fn = handle_nvim_buf_del_extmark, .fast = false, .arena_return = false},
  { .name = "nvim_eval_statusline", .fn = handle_nvim_eval_statusline, .fast = true, .arena_return = false},
  { .name = "vim_del_current_line", .fn = handle_nvim_del_current_line, .fast = false, .arena_return = false},
  { .name = "vim_get_current_line", .fn = handle_nvim_get_current_line, .fast = false, .arena_return = false},
  { .name = "vim_set_current_line", .fn = handle_nvim_set_current_line, .fast = false, .arena_return = false},
  { .name = "nvim_get_current_buf", .fn = handle_nvim_get_current_buf, .fast = false, .arena_return = false},
  { .name = "nvim_get_current_win", .fn = handle_nvim_get_current_win, .fast = false, .arena_return = false},
  { .name = "nvim_get_option_info", .fn = handle_nvim_get_option_info, .fast = false, .arena_return = false},
  { .name = "vim_change_directory", .fn = handle_nvim_set_current_dir, .fast = false, .arena_return = false},
  { .name = "buffer_add_highlight", .fn = handle_nvim_buf_add_highlight, .fast = false, .arena_return = false},
  { .name = "nvim_set_current_dir", .fn = handle_nvim_set_current_dir, .fast = false, .arena_return = false},
  { .name = "nvim_set_current_buf", .fn = handle_nvim_set_current_buf, .fast = false, .arena_return = false},
  { .name = "nvim_set_client_info", .fn = handle_nvim_set_client_info, .fast = false, .arena_return = false},
  { .name = "nvim_set_current_win", .fn = handle_nvim_set_current_win, .fast = false, .arena_return = false},
  { .name = "nvim_tabpage_get_var", .fn = handle_nvim_tabpage_get_var, .fast = false, .arena_return = false},
  { .name = "nvim_tabpage_del_var", .fn = handle_nvim_tabpage_del_var, .fast = false, .arena_return = false},
  { .name = "nvim_tabpage_get_win", .fn = handle_nvim_tabpage_get_win, .fast = false, .arena_return = false},
  { .name = "nvim_tabpage_set_var", .fn = handle_nvim_tabpage_set_var, .fast = false, .arena_return = false},
  { .name = "nvim_win_get_tabpage", .fn = handle_nvim_win_get_tabpage, .fast = false, .arena_return = false},
  { .name = "nvim__runtime_inspect", .fn = handle_nvim__runtime_inspect, .fast = false, .arena_return = false},
  { .name = "nvim_buf_get_commands", .fn = handle_nvim_buf_get_commands, .fast = false, .arena_return = false},
  { .name = "nvim_buf_get_extmarks", .fn = handle_nvim_buf_get_extmarks, .fast = false, .arena_return = false},
  { .name = "nvim_create_namespace", .fn = handle_nvim_create_namespace, .fast = false, .arena_return = false},
  { .name = "nvim_del_current_line", .fn = handle_nvim_del_current_line, .fast = false, .arena_return = false},
  { .name = "nvim_del_user_command", .fn = handle_nvim_del_user_command, .fast = false, .arena_return = false},
  { .name = "vim_replace_termcodes", .fn = handle_nvim_replace_termcodes, .fast = false, .arena_return = false},
  { .name = "nvim_get_runtime_file", .fn = handle_nvim_get_runtime_file, .fast = true, .arena_return = false},
  { .name = "nvim_get_current_line", .fn = handle_nvim_get_current_line, .fast = false, .arena_return = false},
  { .name = "nvim_get_option_value", .fn = handle_nvim_get_option_value, .fast = false, .arena_return = false},
  { .name = "nvim_parse_expression", .fn = handle_nvim_parse_expression, .fast = true, .arena_return = false},
  { .name = "buffer_get_line_slice", .fn = handle_buffer_get_line_slice, .fast = false, .arena_return = false},
  { .name = "buffer_set_line_slice", .fn = handle_buffer_set_line_slice, .fast = false, .arena_return = false},
  { .name = "nvim_set_current_line", .fn = handle_nvim_set_current_line, .fast = false, .arena_return = false},
  { .name = "nvim_set_option_value", .fn = handle_nvim_set_option_value, .fast = false, .arena_return = false},
  { .name = "nvim_tabpage_is_valid", .fn = handle_nvim_tabpage_is_valid, .fast = false, .arena_return = false},
  { .name = "nvim_win_get_position", .fn = handle_nvim_win_get_position, .fast = false, .arena_return = false},
  { .name = "nvim_del_augroup_by_id", .fn = handle_nvim_del_augroup_by_id, .fast = false, .arena_return = false},
  { .name = "nvim__buf_redraw_range", .fn = handle_nvim__buf_redraw_range, .fast = false, .arena_return = false},
  { .name = "vim_list_runtime_paths", .fn = handle_nvim_list_runtime_paths, .fast = false, .arena_return = false},
  { .name = "nvim_ui_pum_set_bounds", .fn = handle_nvim_ui_pum_set_bounds, .fast = false, .arena_return = false},
  { .name = "vim_get_current_buffer", .fn = handle_nvim_get_current_buf, .fast = false, .arena_return = false},
  { .name = "vim_set_current_buffer", .fn = handle_nvim_set_current_buf, .fast = false, .arena_return = false},
  { .name = "nvim_ui_pum_set_height", .fn = handle_nvim_ui_pum_set_height, .fast = false, .arena_return = false},
  { .name = "buffer_clear_highlight", .fn = handle_nvim_buf_clear_highlight, .fast = false, .arena_return = false},
  { .name = "nvim_buf_add_highlight", .fn = handle_nvim_buf_add_highlight, .fast = false, .arena_return = false},
  { .name = "nvim_get_proc_children", .fn = handle_nvim_get_proc_children, .fast = false, .arena_return = false},
  { .name = "nvim_replace_termcodes", .fn = handle_nvim_replace_termcodes, .fast = false, .arena_return = false},
  { .name = "nvim_tabpage_list_wins", .fn = handle_nvim_tabpage_list_wins, .fast = false, .arena_return = false},
  { .name = "vim_get_current_window", .fn = handle_nvim_get_current_win, .fast = false, .arena_return = false},
  { .name = "vim_set_current_window", .fn = handle_nvim_set_current_win, .fast = false, .arena_return = false},
  { .name = "nvim_get_hl_id_by_name", .fn = handle_nvim_get_hl_id_by_name, .fast = false, .arena_return = false},
  { .name = "nvim_get_color_by_name", .fn = handle_nvim_get_color_by_name, .fast = false, .arena_return = false},
  { .name = "nvim_call_dict_function", .fn = handle_nvim_call_dict_function, .fast = false, .arena_return = false},
  { .name = "vim_get_current_tabpage", .fn = handle_nvim_get_current_tabpage, .fast = false, .arena_return = false},
  { .name = "vim_set_current_tabpage", .fn = handle_nvim_set_current_tabpage, .fast = false, .arena_return = false},
  { .name = "nvim_list_runtime_paths", .fn = handle_nvim_list_runtime_paths, .fast = false, .arena_return = false},
  { .name = "nvim_tabpage_get_number", .fn = handle_nvim_tabpage_get_number, .fast = false, .arena_return = false},
  { .name = "nvim_ui_try_resize_grid", .fn = handle_nvim_ui_try_resize_grid, .fast = false, .arena_return = false},
  { .name = "nvim_create_user_command", .fn = handle_nvim_create_user_command, .fast = false, .arena_return = false},
  { .name = "nvim_buf_clear_highlight", .fn = handle_nvim_buf_clear_highlight, .fast = false, .arena_return = false},
  { .name = "nvim_buf_clear_namespace", .fn = handle_nvim_buf_clear_namespace, .fast = false, .arena_return = false},
  { .name = "nvim_del_augroup_by_name", .fn = handle_nvim_del_augroup_by_name, .fast = false, .arena_return = false},
  { .name = "nvim_get_current_tabpage", .fn = handle_nvim_get_current_tabpage, .fast = false, .arena_return = false},
  { .name = "nvim_set_current_tabpage", .fn = handle_nvim_set_current_tabpage, .fast = false, .arena_return = false},
  { .name = "nvim_buf_get_changedtick", .fn = handle_nvim_buf_get_changedtick, .fast = false, .arena_return = false},
  { .name = "nvim_get_all_options_info", .fn = handle_nvim_get_all_options_info, .fast = false, .arena_return = false},
  { .name = "nvim_buf_del_user_command", .fn = handle_nvim_buf_del_user_command, .fast = false, .arena_return = false},
  { .name = "nvim_buf_set_virtual_text", .fn = handle_nvim_buf_set_virtual_text, .fast = false, .arena_return = false},
  { .name = "nvim_buf_get_extmark_by_id", .fn = handle_nvim_buf_get_extmark_by_id, .fast = false, .arena_return = false},
  { .name = "nvim_select_popupmenu_item", .fn = handle_nvim_select_popupmenu_item, .fast = false, .arena_return = false},
  { .name = "nvim_buf_create_user_command", .fn = handle_nvim_buf_create_user_command, .fast = false, .arena_return = false},
};

int msgpack_rpc_get_handler_for_hash(const char *str, size_t len)
{
  int low = 0, high = 0;
  switch (len) {
    case 6: low = 0; high = 1; break;
    case 8: switch (str[5]) {
      case '_': low = 1; high = 2; break;
      case 'c': low = 2; high = 3; break;
      case 'p': low = 3; high = 4; break;
      case 'v': low = 4; high = 5; break;
      default: break;
    }
    break;
    case 9: switch (str[6]) {
      case 'a': low = 5; high = 7; break;
      case 'c': low = 7; high = 8; break;
      case 'p': low = 8; high = 9; break;
      case 'v': low = 9; high = 10; break;
      case 'x': low = 10; high = 11; break;
      default: break;
    }
    break;
    case 10: switch (str[5]) {
      case 'i': low = 11; high = 12; break;
      case 'p': low = 12; high = 13; break;
      default: break;
    }
    break;
    case 11: switch (str[6]) {
      case 'e': low = 13; high = 14; break;
      case 'l': low = 14; high = 15; break;
      case 'm': low = 15; high = 16; break;
      case 'o': low = 16; high = 17; break;
      case 's': low = 17; high = 18; break;
      case 't': low = 18; high = 20; break;
      default: break;
    }
    break;
    case 12: switch (str[5]) {
      case '_': low = 20; high = 21; break;
      case 'c': low = 21; high = 22; break;
      case 'd': low = 22; high = 23; break;
      case 'e': low = 23; high = 25; break;
      case 'g': low = 25; high = 26; break;
      case 's': low = 26; high = 27; break;
      case 't': low = 27; high = 28; break;
      default: break;
    }
    break;
    case 13: switch (str[9]) {
      case '_': low = 28; high = 31; break;
      case 'h': low = 31; high = 32; break;
      case 'i': low = 32; high = 33; break;
      case 'k': low = 33; high = 34; break;
      case 'm': low = 34; high = 37; break;
      case 'p': low = 37; high = 38; break;
      case 'r': low = 38; high = 41; break;
      case 's': low = 41; high = 43; break;
      case 'v': low = 43; high = 45; break;
      default: break;
    }
    break;
    case 14: switch (str[5]) {
      case '_': low = 45; high = 47; break;
      case 'c': low = 47; high = 48; break;
      case 'e': low = 48; high = 51; break;
      case 'l': low = 51; high = 53; break;
      case 'o': low = 53; high = 55; break;
      case 'p': low = 55; high = 56; break;
      case 'r': low = 56; high = 59; break;
      case 's': low = 59; high = 61; break;
      case 'u': low = 61; high = 63; break;
      case 'w': low = 63; high = 67; break;
      default: break;
    }
    break;
    case 15: switch (str[7]) {
      case '_': low = 67; high = 72; break;
      case 'd': low = 72; high = 73; break;
      case 'e': low = 73; high = 74; break;
      case 'f': low = 74; high = 77; break;
      case 'g': low = 77; high = 80; break;
      case 'i': low = 80; high = 82; break;
      case 'l': low = 82; high = 83; break;
      case 's': low = 83; high = 86; break;
      case 't': low = 86; high = 90; break;
      case 'u': low = 90; high = 92; break;
      default: break;
    }
    break;
    case 16: switch (str[6]) {
      case '_': low = 92; high = 96; break;
      case 'a': low = 96; high = 97; break;
      case 'e': low = 97; high = 100; break;
      case 'i': low = 100; high = 105; break;
      case 'n': low = 105; high = 107; break;
      case 'p': low = 107; high = 108; break;
      case 'r': low = 108; high = 110; break;
      case 's': low = 110; high = 111; break;
      case 't': low = 111; high = 113; break;
      case 'u': low = 113; high = 116; break;
      case 'x': low = 116; high = 117; break;
      default: break;
    }
    break;
    case 17: switch (str[14]) {
      case '_': low = 117; high = 118; break;
      case 'a': low = 118; high = 123; break;
      case 'b': low = 123; high = 124; break;
      case 'd': low = 124; high = 125; break;
      case 'e': low = 125; high = 129; break;
      case 'f': low = 129; high = 130; break;
      case 'g': low = 130; high = 132; break;
      case 'i': low = 132; high = 138; break;
      case 'l': low = 138; high = 141; break;
      case 'm': low = 141; high = 143; break;
      case 'n': low = 143; high = 145; break;
      case 's': low = 145; high = 147; break;
      case 'u': low = 147; high = 148; break;
      default: break;
    }
    break;
    case 18: switch (str[13]) {
      case '_': low = 148; high = 150; break;
      case 'b': low = 150; high = 151; break;
      case 'c': low = 151; high = 152; break;
      case 'e': low = 152; high = 153; break;
      case 'h': low = 153; high = 154; break;
      case 'i': low = 154; high = 155; break;
      case 'l': low = 155; high = 157; break;
      case 'o': low = 157; high = 159; break;
      case 'p': low = 159; high = 161; break;
      case 'r': low = 161; high = 162; break;
      case 'u': low = 162; high = 163; break;
      case 'w': low = 163; high = 165; break;
      default: break;
    }
    break;
    case 19: switch (str[14]) {
      case '_': low = 165; high = 167; break;
      case 'c': low = 167; high = 168; break;
      case 'e': low = 168; high = 173; break;
      case 'f': low = 173; high = 174; break;
      case 'g': low = 174; high = 175; break;
      case 'i': low = 175; high = 176; break;
      case 'n': low = 176; high = 177; break;
      case 'o': low = 177; high = 181; break;
      case 'p': low = 181; high = 186; break;
      case 't': low = 186; high = 187; break;
      case 'u': low = 187; high = 192; break;
      default: break;
    }
    break;
    case 20: switch (str[5]) {
      case 'b': low = 192; high = 194; break;
      case 'e': low = 194; high = 198; break;
      case 'g': low = 198; high = 201; break;
      case 'h': low = 201; high = 202; break;
      case 'r': low = 202; high = 203; break;
      case 's': low = 203; high = 207; break;
      case 't': low = 207; high = 211; break;
      case 'w': low = 211; high = 212; break;
      default: break;
    }
    break;
    case 21: switch (str[5]) {
      case '_': low = 212; high = 213; break;
      case 'b': low = 213; high = 215; break;
      case 'c': low = 215; high = 216; break;
      case 'd': low = 216; high = 218; break;
      case 'e': low = 218; high = 219; break;
      case 'g': low = 219; high = 222; break;
      case 'p': low = 222; high = 223; break;
      case 'r': low = 223; high = 225; break;
      case 's': low = 225; high = 227; break;
      case 't': low = 227; high = 228; break;
      case 'w': low = 228; high = 229; break;
      default: break;
    }
    break;
    case 22: switch (str[16]) {
      case '_': low = 229; high = 232; break;
      case 'b': low = 232; high = 235; break;
      case 'h': low = 235; high = 238; break;
      case 'i': low = 238; high = 239; break;
      case 'm': low = 239; high = 240; break;
      case 't': low = 240; high = 241; break;
      case 'w': low = 241; high = 243; break;
      case 'y': low = 243; high = 245; break;
      default: break;
    }
    break;
    case 23: switch (str[5]) {
      case 'c': low = 245; high = 246; break;
      case 'e': low = 246; high = 248; break;
      case 'l': low = 248; high = 249; break;
      case 't': low = 249; high = 250; break;
      case 'u': low = 250; high = 251; break;
      default: break;
    }
    break;
    case 24: switch (str[11]) {
      case '_': low = 251; high = 252; break;
      case 'e': low = 252; high = 254; break;
      case 'g': low = 254; high = 255; break;
      case 'r': low = 255; high = 257; break;
      case 't': low = 257; high = 258; break;
      default: break;
    }
    break;
    case 25: switch (str[9]) {
      case 'a': low = 258; high = 259; break;
      case 'd': low = 259; high = 260; break;
      case 's': low = 260; high = 261; break;
      default: break;
    }
    break;
    case 26: switch (str[5]) {
      case 'b': low = 261; high = 262; break;
      case 's': low = 262; high = 263; break;
      default: break;
    }
    break;
    case 28: low = 263; high = 264; break;
    default: break;
  }
  for (int i = low; i < high; i++) {
    if (!memcmp(str, method_handlers[i].name, len)) {
      return i;
    }
  }
  return -1;
}

