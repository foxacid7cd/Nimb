static const EvalFuncDef functions[] = {
  { "id", 1, 1, BASE_NONE, false, &f_id, { .nullptr = NULL } },
  { "or", 2, 2, 1, false, &f_or, { .nullptr = NULL } },
  { "tr", 3, 3, 1, false, &f_tr, { .nullptr = NULL } },
  { "add", 2, 2, 1, false, &f_add, { .nullptr = NULL } },
  { "and", 2, 2, 1, false, &f_and, { .nullptr = NULL } },
  { "abs", 1, 1, 1, false, &f_abs, { .nullptr = NULL } },
  { "cos", 1, 1, 1, false, &float_op_wrapper, { .float_func = &cos } },
  { "col", 1, 1, 1, false, &f_col, { .nullptr = NULL } },
  { "exp", 1, 1, 1, false, &float_op_wrapper, { .float_func = &exp } },
  { "get", 2, 3, 1, false, &f_get, { .nullptr = NULL } },
  { "has", 1, 1, BASE_NONE, false, &f_has, { .nullptr = NULL } },
  { "len", 1, 1, 1, false, &f_len, { .nullptr = NULL } },
  { "log", 1, 1, 1, false, &float_op_wrapper, { .float_func = &log } },
  { "min", 1, 1, 1, false, &f_min, { .nullptr = NULL } },
  { "max", 1, 1, 1, false, &f_max, { .nullptr = NULL } },
  { "map", 2, 2, 1, false, &f_map, { .nullptr = NULL } },
  { "pow", 2, 2, 1, false, &f_pow, { .nullptr = NULL } },
  { "sin", 1, 1, 1, false, &float_op_wrapper, { .float_func = &sin } },
  { "tan", 1, 1, 1, false, &float_op_wrapper, { .float_func = &tan } },
  { "xor", 2, 2, 1, false, &f_xor, { .nullptr = NULL } },
  { "hlID", 1, 1, 1, false, &f_hlID, { .nullptr = NULL } },
  { "glob", 1, 4, 1, false, &f_glob, { .nullptr = NULL } },
  { "argc", 0, 1, BASE_NONE, false, &f_argc, { .nullptr = NULL } },
  { "fmod", 2, 2, 1, false, &f_fmod, { .nullptr = NULL } },
  { "rand", 0, 1, 1, false, &f_rand, { .nullptr = NULL } },
  { "type", 1, 1, 1, false, &f_type, { .nullptr = NULL } },
  { "line", 1, 2, 1, false, &f_line, { .nullptr = NULL } },
  { "mode", 0, 1, 1, false, &f_mode, { .nullptr = NULL } },
  { "sinh", 1, 1, 1, false, &float_op_wrapper, { .float_func = &sinh } },
  { "cosh", 1, 1, 1, false, &float_op_wrapper, { .float_func = &cosh } },
  { "tanh", 1, 1, 1, false, &float_op_wrapper, { .float_func = &tanh } },
  { "call", 2, 3, 1, false, &f_call, { .nullptr = NULL } },
  { "ceil", 1, 1, 1, false, &float_op_wrapper, { .float_func = &ceil } },
  { "eval", 1, 1, 1, false, &f_eval, { .nullptr = NULL } },
  { "trim", 1, 3, 1, false, &f_trim, { .nullptr = NULL } },
  { "asin", 1, 1, 1, false, &float_op_wrapper, { .float_func = &asin } },
  { "atan", 1, 1, 1, false, &float_op_wrapper, { .float_func = &atan } },
  { "join", 1, 2, 1, false, &f_join, { .nullptr = NULL } },
  { "uniq", 1, 3, 1, false, &f_uniq, { .nullptr = NULL } },
  { "acos", 1, 1, 1, false, &float_op_wrapper, { .float_func = &acos } },
  { "keys", 1, 1, 1, false, &f_keys, { .nullptr = NULL } },
  { "sqrt", 1, 1, 1, false, &float_op_wrapper, { .float_func = &sqrt } },
  { "sort", 1, 3, 1, false, &f_sort, { .nullptr = NULL } },
  { "wait", 2, 3, BASE_NONE, false, &f_wait, { .nullptr = NULL } },
  { "argv", 0, 2, BASE_NONE, false, &f_argv, { .nullptr = NULL } },
  { "copy", 1, 1, 1, false, &f_copy, { .nullptr = NULL } },
  { "match", 2, 4, 1, false, &f_match, { .nullptr = NULL } },
  { "range", 1, 3, 1, false, &f_range, { .nullptr = NULL } },
  { "iconv", 3, 3, 1, true, &f_iconv, { .nullptr = NULL } },
  { "chdir", 1, 1, 1, false, &f_chdir, { .nullptr = NULL } },
  { "winnr", 0, 1, 1, false, &f_winnr, { .nullptr = NULL } },
  { "mkdir", 1, 3, 1, false, &f_mkdir, { .nullptr = NULL } },
  { "floor", 1, 1, 1, false, &float_op_wrapper, { .float_func = &floor } },
  { "empty", 1, 1, 1, false, &f_empty, { .nullptr = NULL } },
  { "index", 2, 4, 1, false, &f_index, { .nullptr = NULL } },
  { "input", 1, 3, 1, false, &f_input, { .nullptr = NULL } },
  { "count", 2, 4, 1, false, &f_count, { .nullptr = NULL } },
  { "log10", 1, 1, 1, false, &float_op_wrapper, { .float_func = &log10 } },
  { "round", 1, 1, 1, false, &float_op_wrapper, { .float_func = &round } },
  { "split", 1, 3, 1, false, &f_split, { .nullptr = NULL } },
  { "srand", 0, 1, 1, false, &f_srand, { .nullptr = NULL } },
  { "trunc", 1, 1, 1, false, &float_op_wrapper, { .float_func = &trunc } },
  { "isinf", 1, 1, 1, false, &f_isinf, { .nullptr = NULL } },
  { "isnan", 1, 1, 1, false, &f_isnan, { .nullptr = NULL } },
  { "atan2", 2, 2, 1, false, &f_atan2, { .nullptr = NULL } },
  { "items", 1, 1, 1, false, &f_items, { .nullptr = NULL } },
  { "bufnr", 0, 2, 1, false, &f_bufnr, { .nullptr = NULL } },
  { "synID", 3, 3, BASE_NONE, false, &f_synID, { .nullptr = NULL } },
  { "sha256", 1, 1, 1, false, &f_sha256, { .nullptr = NULL } },
  { "append", 2, 2, 2, false, &f_append, { .nullptr = NULL } },
  { "expand", 1, 3, 1, false, &f_expand, { .nullptr = NULL } },
  { "extend", 2, 3, 1, false, &f_extend, { .nullptr = NULL } },
  { "getcwd", 0, 2, 1, false, &f_getcwd, { .nullptr = NULL } },
  { "bufadd", 1, 1, 1, false, &f_bufadd, { .nullptr = NULL } },
  { "getpid", 0, 0, BASE_NONE, false, &f_getpid, { .nullptr = NULL } },
  { "jobpid", 1, 1, BASE_NONE, false, &f_jobpid, { .nullptr = NULL } },
  { "rename", 2, 2, 1, false, &f_rename, { .nullptr = NULL } },
  { "browse", 4, 4, BASE_NONE, false, &f_browse, { .nullptr = NULL } },
  { "delete", 1, 2, 1, false, &f_delete, { .nullptr = NULL } },
  { "escape", 2, 2, 1, false, &f_escape, { .nullptr = NULL } },
  { "remove", 2, 3, 1, false, &f_remove, { .nullptr = NULL } },
  { "reduce", 2, 3, 1, false, &f_reduce, { .nullptr = NULL } },
  { "printf", 1, MAX_FUNC_ARGS, 2, false, &f_printf, { .nullptr = NULL } },
  { "string", 1, 1, 1, false, &f_string, { .nullptr = NULL } },
  { "getreg", 0, 3, 1, false, &f_getreg, { .nullptr = NULL } },
  { "maparg", 1, 4, 1, false, &f_maparg, { .nullptr = NULL } },
  { "setreg", 2, 3, 2, false, &f_setreg, { .nullptr = NULL } },
  { "search", 1, 5, 1, false, &f_search, { .nullptr = NULL } },
  { "wincol", 0, 0, BASE_NONE, false, &f_wincol, { .nullptr = NULL } },
  { "pyeval", 1, 1, 1, false, &f_py3eval, { .nullptr = NULL } },
  { "system", 1, 2, 1, false, &f_system, { .nullptr = NULL } },
  { "strlen", 1, 1, 1, false, &f_strlen, { .nullptr = NULL } },
  { "ctxpop", 0, 0, BASE_NONE, false, &f_ctxpop, { .nullptr = NULL } },
  { "filter", 2, 2, 1, false, &f_filter, { .nullptr = NULL } },
  { "str2nr", 1, 3, 1, false, &f_str2nr, { .nullptr = NULL } },
  { "cursor", 1, 3, 1, false, &f_cursor, { .nullptr = NULL } },
  { "histnr", 1, 1, 1, false, &f_histnr, { .nullptr = NULL } },
  { "exists", 1, 1, 1, false, &f_exists, { .nullptr = NULL } },
  { "values", 1, 1, 1, false, &f_values, { .nullptr = NULL } },
  { "getpos", 1, 1, 1, false, &f_getpos, { .nullptr = NULL } },
  { "setpos", 2, 2, 2, false, &f_setpos, { .nullptr = NULL } },
  { "ctxget", 0, 1, BASE_NONE, false, &f_ctxget, { .nullptr = NULL } },
  { "ctxset", 1, 2, BASE_NONE, false, &f_ctxset, { .nullptr = NULL } },
  { "indent", 1, 1, 1, false, &f_indent, { .nullptr = NULL } },
  { "insert", 2, 3, 1, false, &f_insert, { .nullptr = NULL } },
  { "repeat", 2, 2, 1, false, &f_repeat, { .nullptr = NULL } },
  { "invert", 1, 1, 1, false, &f_invert, { .nullptr = NULL } },
  { "mapset", 3, 3, 1, false, &f_mapset, { .nullptr = NULL } },
  { "getenv", 1, 1, 1, false, &f_getenv, { .nullptr = NULL } },
  { "setenv", 2, 2, 2, false, &f_setenv, { .nullptr = NULL } },
  { "argidx", 0, 0, BASE_NONE, false, &f_argidx, { .nullptr = NULL } },
  { "stridx", 2, 3, 1, false, &f_stridx, { .nullptr = NULL } },
  { "nr2char", 1, 2, 1, false, &f_nr2char, { .nullptr = NULL } },
  { "py3eval", 1, 1, 1, false, &f_py3eval, { .nullptr = NULL } },
  { "charidx", 2, 3, 1, false, &f_charidx, { .nullptr = NULL } },
  { "flatten", 1, 2, 1, false, &f_flatten, { .nullptr = NULL } },
  { "char2nr", 1, 2, 1, false, &f_char2nr, { .nullptr = NULL } },
  { "charcol", 1, 1, 1, false, &f_charcol, { .nullptr = NULL } },
  { "luaeval", 1, 2, 1, false, &f_luaeval, { .nullptr = NULL } },
  { "readdir", 1, 2, 1, false, &f_readdir, { .nullptr = NULL } },
  { "jobsend", 2, 2, BASE_NONE, false, &f_chansend, { .nullptr = NULL } },
  { "jobstop", 1, 1, BASE_NONE, false, &f_jobstop, { .nullptr = NULL } },
  { "jobwait", 1, 2, BASE_NONE, false, &f_jobwait, { .nullptr = NULL } },
  { "libcall", 3, 3, 3, false, &f_libcall, { .nullptr = NULL } },
  { "rpcstop", 1, 1, BASE_NONE, false, &f_rpcstop, { .nullptr = NULL } },
  { "stdpath", 1, 1, BASE_NONE, false, &f_stdpath, { .nullptr = NULL } },
  { "execute", 1, 2, 1, false, &f_execute, { .nullptr = NULL } },
  { "exepath", 1, 1, 1, false, &f_exepath, { .nullptr = NULL } },
  { "bufload", 1, 1, 1, false, &f_bufload, { .nullptr = NULL } },
  { "bufname", 0, 1, 1, false, &f_bufname, { .nullptr = NULL } },
  { "taglist", 1, 2, 1, false, &f_taglist, { .nullptr = NULL } },
  { "tolower", 1, 1, 1, false, &f_tolower, { .nullptr = NULL } },
  { "reltime", 0, 2, 1, false, &f_reltime, { .nullptr = NULL } },
  { "cindent", 1, 1, 1, false, &f_cindent, { .nullptr = NULL } },
  { "confirm", 1, 4, 1, false, &f_confirm, { .nullptr = NULL } },
  { "finddir", 1, 3, 1, false, &f_finddir, { .nullptr = NULL } },
  { "funcref", 1, 3, 1, false, &f_funcref, { .nullptr = NULL } },
  { "winline", 0, 0, BASE_NONE, false, &f_winline, { .nullptr = NULL } },
  { "strpart", 2, 4, 1, false, &f_strpart, { .nullptr = NULL } },
  { "strridx", 2, 3, 1, false, &f_strridx, { .nullptr = NULL } },
  { "virtcol", 1, 1, 1, false, &f_virtcol, { .nullptr = NULL } },
  { "histget", 1, 2, 1, false, &f_histget, { .nullptr = NULL } },
  { "has_key", 2, 2, 1, false, &f_has_key, { .nullptr = NULL } },
  { "histadd", 2, 2, 2, false, &f_histadd, { .nullptr = NULL } },
  { "histdel", 1, 2, 1, false, &f_histdel, { .nullptr = NULL } },
  { "resolve", 1, 1, 1, false, &f_resolve, { .nullptr = NULL } },
  { "byteidx", 2, 2, 1, false, &f_byteidx, { .nullptr = NULL } },
  { "getchar", 0, 1, BASE_NONE, false, &f_getchar, { .nullptr = NULL } },
  { "getline", 1, 2, 1, false, &f_getline, { .nullptr = NULL } },
  { "gettext", 1, 1, 1, false, &f_gettext, { .nullptr = NULL } },
  { "setline", 2, 2, 2, false, &f_setline, { .nullptr = NULL } },
  { "toupper", 1, 1, 1, false, &f_toupper, { .nullptr = NULL } },
  { "reverse", 1, 1, 1, false, &f_reverse, { .nullptr = NULL } },
  { "environ", 0, 0, BASE_NONE, false, &f_environ, { .nullptr = NULL } },
  { "ctxsize", 0, 0, BASE_NONE, false, &f_ctxsize, { .nullptr = NULL } },
  { "ctxpush", 0, 1, BASE_NONE, false, &f_ctxpush, { .nullptr = NULL } },
  { "pyxeval", 1, 1, 1, false, &f_py3eval, { .nullptr = NULL } },
  { "str2list", 1, 2, 1, false, &f_str2list, { .nullptr = NULL } },
  { "api_info", 0, 0, BASE_NONE, false, &f_api_info, { .nullptr = NULL } },
  { "float2nr", 1, 1, 1, false, &f_float2nr, { .nullptr = NULL } },
  { "winbufnr", 1, 1, 1, false, &f_winbufnr, { .nullptr = NULL } },
  { "globpath", 2, 5, 2, false, &f_globpath, { .nullptr = NULL } },
  { "strchars", 1, 2, 1, false, &f_strchars, { .nullptr = NULL } },
  { "function", 1, 3, 1, false, &f_function, { .nullptr = NULL } },
  { "jobclose", 1, 2, BASE_NONE, false, &f_chanclose, { .nullptr = NULL } },
  { "mapcheck", 1, 3, 1, false, &f_mapcheck, { .nullptr = NULL } },
  { "matchadd", 2, 5, 1, false, &f_matchadd, { .nullptr = NULL } },
  { "matcharg", 1, 1, 1, false, &f_matcharg, { .nullptr = NULL } },
  { "matchend", 2, 4, 1, false, &f_matchend, { .nullptr = NULL } },
  { "matchstr", 2, 4, 1, false, &f_matchstr, { .nullptr = NULL } },
  { "feedkeys", 1, 2, 1, false, &f_feedkeys, { .nullptr = NULL } },
  { "findfile", 1, 3, 1, false, &f_findfile, { .nullptr = NULL } },
  { "foldtext", 0, 0, BASE_NONE, false, &f_foldtext, { .nullptr = NULL } },
  { "readblob", 1, 1, 1, false, &f_readblob, { .nullptr = NULL } },
  { "readfile", 1, 3, 1, false, &f_readfile, { .nullptr = NULL } },
  { "getfperm", 1, 1, 1, false, &f_getfperm, { .nullptr = NULL } },
  { "getfsize", 1, 1, 1, false, &f_getfsize, { .nullptr = NULL } },
  { "getftime", 1, 1, 1, false, &f_getftime, { .nullptr = NULL } },
  { "getftype", 1, 1, 1, false, &f_getftype, { .nullptr = NULL } },
  { "strftime", 1, 2, 1, false, &f_strftime, { .nullptr = NULL } },
  { "tagfiles", 0, 0, BASE_NONE, false, &f_tagfiles, { .nullptr = NULL } },
  { "setfperm", 2, 2, 1, false, &f_setfperm, { .nullptr = NULL } },
  { "perleval", 1, 1, 1, false, &f_perleval, { .nullptr = NULL } },
  { "submatch", 1, 2, 1, false, &f_submatch, { .nullptr = NULL } },
  { "termopen", 1, 2, BASE_NONE, false, &f_termopen, { .nullptr = NULL } },
  { "nvim_put", 4, 4, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[3] } },
  { "nvim__id", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[1] } },
  { "nvim_cmd", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[2] } },
  { "hasmapto", 1, 3, 1, false, &f_hasmapto, { .nullptr = NULL } },
  { "changenr", 0, 0, BASE_NONE, false, &f_changenr, { .nullptr = NULL } },
  { "chansend", 2, 2, BASE_NONE, false, &f_chansend, { .nullptr = NULL } },
  { "undofile", 1, 1, 1, false, &f_undofile, { .nullptr = NULL } },
  { "undotree", 0, 0, BASE_NONE, false, &f_undotree, { .nullptr = NULL } },
  { "islocked", 1, 1, 1, false, &f_islocked, { .nullptr = NULL } },
  { "simplify", 1, 1, 1, false, &f_simplify, { .nullptr = NULL } },
  { "strptime", 2, 2, 1, false, &f_strptime, { .nullptr = NULL } },
  { "swapinfo", 1, 1, 1, false, &f_swapinfo, { .nullptr = NULL } },
  { "swapname", 1, 1, 1, false, &f_swapname, { .nullptr = NULL } },
  { "tempname", 0, 0, BASE_NONE, false, &f_tempname, { .nullptr = NULL } },
  { "complete", 2, 2, 2, false, &f_complete, { .nullptr = NULL } },
  { "deepcopy", 1, 2, 1, false, &f_deepcopy, { .nullptr = NULL } },
  { "synstack", 2, 2, BASE_NONE, false, &f_synstack, { .nullptr = NULL } },
  { "rpcstart", 1, 2, BASE_NONE, false, &f_rpcstart, { .nullptr = NULL } },
  { "jobstart", 1, 2, BASE_NONE, false, &f_jobstart, { .nullptr = NULL } },
  { "strtrans", 1, 1, 1, false, &f_strtrans, { .nullptr = NULL } },
  { "hostname", 0, 0, BASE_NONE, false, &f_hostname, { .nullptr = NULL } },
  { "list2str", 1, 2, 1, false, &f_list2str, { .nullptr = NULL } },
  { "keytrans", 1, 1, 1, false, &f_keytrans, { .nullptr = NULL } },
  { "menu_get", 1, 2, BASE_NONE, false, &f_menu_get, { .nullptr = NULL } },
  { "bufwinid", 1, 1, 1, false, &f_bufwinid, { .nullptr = NULL } },
  { "bufwinnr", 1, 1, 1, false, &f_bufwinnr, { .nullptr = NULL } },
  { "strwidth", 1, 1, 1, false, &f_strwidth, { .nullptr = NULL } },
  { "winwidth", 1, 1, 1, false, &f_winwidth, { .nullptr = NULL } },
  { "hlexists", 1, 1, 1, false, &f_hlexists, { .nullptr = NULL } },
  { "rubyeval", 1, 1, 1, false, &f_rubyeval, { .nullptr = NULL } },
  { "byte2line", 1, 1, 1, false, &f_byte2line, { .nullptr = NULL } },
  { "line2byte", 1, 1, 1, false, &f_line2byte, { .nullptr = NULL } },
  { "synIDattr", 2, 3, 1, false, &f_synIDattr, { .nullptr = NULL } },
  { "diff_hlID", 2, 2, 1, false, &f_diff_hlID, { .nullptr = NULL } },
  { "sign_jump", 3, 3, 1, false, &f_sign_jump, { .nullptr = NULL } },
  { "nvim_echo", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[7] } },
  { "nvim_eval", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[9] } },
  { "nvim_exec", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[10] } },
  { "menu_info", 1, 2, 1, false, &f_menu_info, { .nullptr = NULL } },
  { "tabpagenr", 0, 1, BASE_NONE, false, &f_tabpagenr, { .nullptr = NULL } },
  { "winlayout", 0, 1, 1, false, &f_winlayout, { .nullptr = NULL } },
  { "gettabvar", 2, 3, 1, false, &f_gettabvar, { .nullptr = NULL } },
  { "libcallnr", 3, 3, 3, false, &f_libcallnr, { .nullptr = NULL } },
  { "settabvar", 3, 3, 3, false, &f_settabvar, { .nullptr = NULL } },
  { "chanclose", 1, 2, BASE_NONE, false, &f_chanclose, { .nullptr = NULL } },
  { "wordcount", 0, 0, BASE_NONE, false, &f_wordcount, { .nullptr = NULL } },
  { "charclass", 1, 1, 1, false, &f_charclass, { .nullptr = NULL } },
  { "searchpos", 1, 5, 1, false, &f_searchpos, { .nullptr = NULL } },
  { "soundfold", 1, 1, 1, false, &f_soundfold, { .nullptr = NULL } },
  { "winheight", 1, 1, 1, false, &f_winheight, { .nullptr = NULL } },
  { "writefile", 2, 3, 1, false, &f_writefile, { .nullptr = NULL } },
  { "jobresize", 3, 3, BASE_NONE, false, &f_jobresize, { .nullptr = NULL } },
  { "screencol", 0, 0, BASE_NONE, false, &f_screencol, { .nullptr = NULL } },
  { "screenpos", 3, 3, 1, false, &f_screenpos, { .nullptr = NULL } },
  { "screenrow", 0, 0, BASE_NONE, false, &f_screenrow, { .nullptr = NULL } },
  { "str2float", 1, 1, 1, false, &f_str2float, { .nullptr = NULL } },
  { "getqflist", 0, 1, BASE_NONE, false, &f_getqflist, { .nullptr = NULL } },
  { "setqflist", 1, 3, 1, false, &f_setqflist, { .nullptr = NULL } },
  { "win_getid", 0, 2, 1, false, &f_win_getid, { .nullptr = NULL } },
  { "matchlist", 2, 4, 1, false, &f_matchlist, { .nullptr = NULL } },
  { "setwinvar", 3, 3, 3, false, &f_setwinvar, { .nullptr = NULL } },
  { "arglistid", 0, 2, BASE_NONE, false, &f_arglistid, { .nullptr = NULL } },
  { "buflisted", 1, 1, 1, false, &f_buflisted, { .nullptr = NULL } },
  { "getwinpos", 0, 1, 1, false, &f_getwinpos, { .nullptr = NULL } },
  { "getwinvar", 2, 3, 1, false, &f_getwinvar, { .nullptr = NULL } },
  { "foldlevel", 1, 1, 1, false, &f_foldlevel, { .nullptr = NULL } },
  { "localtime", 0, 0, BASE_NONE, false, &f_localtime, { .nullptr = NULL } },
  { "getcmdpos", 0, 0, BASE_NONE, false, &f_getcmdpos, { .nullptr = NULL } },
  { "setcmdpos", 1, 1, 1, false, &f_setcmdpos, { .nullptr = NULL } },
  { "expandcmd", 1, 2, 1, false, &f_expandcmd, { .nullptr = NULL } },
  { "bufloaded", 1, 1, 1, false, &f_bufloaded, { .nullptr = NULL } },
  { "stdioopen", 1, 1, BASE_NONE, false, &f_stdioopen, { .nullptr = NULL } },
  { "rpcnotify", 2, MAX_FUNC_ARGS, BASE_NONE, false, &f_rpcnotify, { .nullptr = NULL } },
  { "interrupt", 0, 0, BASE_NONE, false, &f_interrupt, { .nullptr = NULL } },
  { "browsedir", 2, 2, BASE_NONE, false, &f_browsedir, { .nullptr = NULL } },
  { "inputlist", 1, 1, 1, false, &f_inputlist, { .nullptr = NULL } },
  { "inputsave", 0, 0, BASE_NONE, false, &f_inputsave, { .nullptr = NULL } },
  { "getbufvar", 2, 3, 1, false, &f_getbufvar, { .nullptr = NULL } },
  { "getcurpos", 0, 1, 1, false, &f_getcurpos, { .nullptr = NULL } },
  { "setbufvar", 3, 3, 3, false, &f_setbufvar, { .nullptr = NULL } },
  { "bufexists", 1, 1, 1, false, &f_bufexists, { .nullptr = NULL } },
  { "timer_info", 0, 1, 1, false, &f_timer_info, { .nullptr = NULL } },
  { "timer_stop", 1, 1, 1, false, &f_timer_stop, { .nullptr = NULL } },
  { "getcharmod", 0, 0, BASE_NONE, false, &f_getcharmod, { .nullptr = NULL } },
  { "getcharpos", 1, 1, 1, false, &f_getcharpos, { .nullptr = NULL } },
  { "getcharstr", 0, 1, BASE_NONE, false, &f_getcharstr, { .nullptr = NULL } },
  { "strcharlen", 1, 1, 1, false, &f_strcharlen, { .nullptr = NULL } },
  { "setcharpos", 2, 2, 2, false, &f_setcharpos, { .nullptr = NULL } },
  { "debugbreak", 1, 1, 1, false, &f_debugbreak, { .nullptr = NULL } },
  { "gettabinfo", 0, 1, 1, false, &f_gettabinfo, { .nullptr = NULL } },
  { "getloclist", 1, 2, BASE_NONE, false, &f_getloclist, { .nullptr = NULL } },
  { "setloclist", 2, 4, 2, false, &f_setloclist, { .nullptr = NULL } },
  { "getcmdline", 0, 0, BASE_NONE, false, &f_getcmdline, { .nullptr = NULL } },
  { "getcmdtype", 0, 0, BASE_NONE, false, &f_getcmdtype, { .nullptr = NULL } },
  { "win_id2win", 1, 1, 1, false, &f_win_id2win, { .nullptr = NULL } },
  { "setcmdline", 1, 2, 1, false, &f_setcmdline, { .nullptr = NULL } },
  { "pum_getpos", 0, 0, BASE_NONE, false, &f_pum_getpos, { .nullptr = NULL } },
  { "getbufinfo", 0, 1, 1, false, &f_getbufinfo, { .nullptr = NULL } },
  { "getbufline", 2, 3, 1, false, &f_getbufline, { .nullptr = NULL } },
  { "matchfuzzy", 2, 3, 1, false, &f_matchfuzzy, { .nullptr = NULL } },
  { "setbufline", 3, 3, 3, false, &f_setbufline, { .nullptr = NULL } },
  { "getreginfo", 0, 1, 1, false, &f_getreginfo, { .nullptr = NULL } },
  { "getregtype", 0, 1, 1, false, &f_getregtype, { .nullptr = NULL } },
  { "searchdecl", 1, 3, 1, false, &f_searchdecl, { .nullptr = NULL } },
  { "searchpair", 3, 7, BASE_NONE, false, &f_searchpair, { .nullptr = NULL } },
  { "substitute", 4, 4, 1, false, &f_substitute, { .nullptr = NULL } },
  { "nvim_input", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[11] } },
  { "foldclosed", 1, 1, 1, false, &f_foldclosed, { .nullptr = NULL } },
  { "visualmode", 0, 1, BASE_NONE, false, &f_visualmode, { .nullptr = NULL } },
  { "systemlist", 1, 3, 1, false, &f_systemlist, { .nullptr = NULL } },
  { "reltimestr", 1, 1, 1, false, &f_reltimestr, { .nullptr = NULL } },
  { "getwininfo", 0, 1, 1, false, &f_getwininfo, { .nullptr = NULL } },
  { "getwinposx", 0, 0, BASE_NONE, false, &f_getwinposx, { .nullptr = NULL } },
  { "getwinposy", 0, 0, BASE_NONE, false, &f_getwinposy, { .nullptr = NULL } },
  { "lispindent", 1, 1, 1, false, &f_lispindent, { .nullptr = NULL } },
  { "screenattr", 2, 2, 1, false, &f_screenattr, { .nullptr = NULL } },
  { "screenchar", 2, 2, 1, false, &f_screenchar, { .nullptr = NULL } },
  { "win_gotoid", 1, 1, 1, false, &f_win_gotoid, { .nullptr = NULL } },
  { "sign_place", 4, 5, 1, false, &f_sign_place, { .nullptr = NULL } },
  { "nvim_paste", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[12] } },
  { "rpcrequest", 2, MAX_FUNC_ARGS, BASE_NONE, false, &f_rpcrequest, { .nullptr = NULL } },
  { "foreground", 0, 0, BASE_NONE, false, &f_foreground, { .nullptr = NULL } },
  { "serverlist", 0, 0, BASE_NONE, false, &f_serverlist, { .nullptr = NULL } },
  { "serverstop", 1, 1, BASE_NONE, false, &f_serverstop, { .nullptr = NULL } },
  { "winrestcmd", 0, 0, BASE_NONE, false, &f_winrestcmd, { .nullptr = NULL } },
  { "pumvisible", 0, 0, BASE_NONE, false, &f_pumvisible, { .nullptr = NULL } },
  { "executable", 1, 1, 1, false, &f_executable, { .nullptr = NULL } },
  { "getmatches", 0, 1, BASE_NONE, false, &f_getmatches, { .nullptr = NULL } },
  { "strgetchar", 2, 2, 1, false, &f_strgetchar, { .nullptr = NULL } },
  { "synIDtrans", 1, 1, 1, false, &f_synIDtrans, { .nullptr = NULL } },
  { "setmatches", 1, 2, 1, false, &f_setmatches, { .nullptr = NULL } },
  { "shiftwidth", 0, 1, 1, false, &f_shiftwidth, { .nullptr = NULL } },
  { "timer_pause", 2, 2, 1, false, &f_timer_pause, { .nullptr = NULL } },
  { "timer_start", 2, 3, 1, false, &f_timer_start, { .nullptr = NULL } },
  { "nvim__stats", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[17] } },
  { "strcharpart", 2, 3, 1, false, &f_strcharpart, { .nullptr = NULL } },
  { "matchaddpos", 2, 5, 1, false, &f_matchaddpos, { .nullptr = NULL } },
  { "haslocaldir", 0, 2, 1, false, &f_haslocaldir, { .nullptr = NULL } },
  { "msgpackdump", 1, 2, BASE_NONE, false, &f_msgpackdump, { .nullptr = NULL } },
  { "sign_define", 1, 2, 1, false, &f_sign_define, { .nullptr = NULL } },
  { "inputdialog", 1, 3, 1, false, &f_inputdialog, { .nullptr = NULL } },
  { "byteidxcomp", 2, 2, 1, false, &f_byteidxcomp, { .nullptr = NULL } },
  { "json_decode", 1, 1, 1, false, &f_json_decode, { .nullptr = NULL } },
  { "matchdelete", 1, 2, 1, false, &f_matchdelete, { .nullptr = NULL } },
  { "shellescape", 1, 2, 1, false, &f_shellescape, { .nullptr = NULL } },
  { "fnameescape", 1, 1, 1, false, &f_fnameescape, { .nullptr = NULL } },
  { "win_gettype", 0, 1, 1, false, &f_win_gettype, { .nullptr = NULL } },
  { "isdirectory", 1, 1, 1, false, &f_isdirectory, { .nullptr = NULL } },
  { "json_encode", 1, 1, 1, false, &f_json_encode, { .nullptr = NULL } },
  { "diff_filler", 1, 1, 1, false, &f_diff_filler, { .nullptr = NULL } },
  { "settagstack", 2, 3, 2, false, &f_settagstack, { .nullptr = NULL } },
  { "gettagstack", 0, 1, 1, false, &f_gettagstack, { .nullptr = NULL } },
  { "pathshorten", 1, 2, 1, false, &f_pathshorten, { .nullptr = NULL } },
  { "searchcount", 0, 1, 1, false, &f_searchcount, { .nullptr = NULL } },
  { "win_findbuf", 1, 1, 1, false, &f_win_findbuf, { .nullptr = NULL } },
  { "highlightID", 1, 1, 1, false, &f_hlID, { .nullptr = NULL } },
  { "fnamemodify", 2, 2, 1, false, &f_fnamemodify, { .nullptr = NULL } },
  { "getjumplist", 0, 2, 1, false, &f_getjumplist, { .nullptr = NULL } },
  { "getfontname", 0, 1, BASE_NONE, false, &f_getfontname, { .nullptr = NULL } },
  { "nvim_notify", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[16] } },
  { "screenchars", 2, 2, 1, false, &f_screenchars, { .nullptr = NULL } },
  { "fullcommand", 1, 1, 1, false, &f_fullcommand, { .nullptr = NULL } },
  { "virtcol2col", 3, 3, 1, false, &f_virtcol2col, { .nullptr = NULL } },
  { "sockconnect", 2, 3, BASE_NONE, false, &f_sockconnect, { .nullptr = NULL } },
  { "digraph_get", 1, 1, 1, false, &f_digraph_get, { .nullptr = NULL } },
  { "digraph_set", 2, 2, 1, false, &f_digraph_set, { .nullptr = NULL } },
  { "buffer_name", 0, 1, 1, false, &f_bufname, { .nullptr = NULL } },
  { "getmarklist", 0, 1, 1, false, &f_getmarklist, { .nullptr = NULL } },
  { "glob2regpat", 1, 1, 1, false, &f_glob2regpat, { .nullptr = NULL } },
  { "serverstart", 0, 1, BASE_NONE, false, &f_serverstart, { .nullptr = NULL } },
  { "winrestview", 1, 1, 1, false, &f_winrestview, { .nullptr = NULL } },
  { "nvim_set_hl", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[13] } },
  { "inputsecret", 1, 2, 1, false, &f_inputsecret, { .nullptr = NULL } },
  { "matchstrpos", 2, 4, 1, false, &f_matchstrpos, { .nullptr = NULL } },
  { "assert_true", 1, 2, 1, false, &f_assert_true, { .nullptr = NULL } },
  { "getmousepos", 0, 0, BASE_NONE, false, &f_getmousepos, { .nullptr = NULL } },
  { "winsaveview", 0, 0, BASE_NONE, false, &f_winsaveview, { .nullptr = NULL } },
  { "win_execute", 2, 3, 2, false, &f_win_execute, { .nullptr = NULL } },
  { "tabpagewinnr", 1, 2, 1, false, &f_tabpagewinnr, { .nullptr = NULL } },
  { "did_filetype", 0, 0, BASE_NONE, false, &f_did_filetype, { .nullptr = NULL } },
  { "eventhandler", 0, 0, BASE_NONE, false, &f_eventhandler, { .nullptr = NULL } },
  { "spellbadword", 0, 1, 1, false, &f_spellbadword, { .nullptr = NULL } },
  { "spellsuggest", 1, 3, 1, false, &f_spellsuggest, { .nullptr = NULL } },
  { "clearmatches", 0, 1, 1, false, &f_clearmatches, { .nullptr = NULL } },
  { "prevnonblank", 1, 1, 1, false, &f_prevnonblank, { .nullptr = NULL } },
  { "sign_unplace", 1, 2, 1, false, &f_sign_unplace, { .nullptr = NULL } },
  { "msgpackparse", 1, 1, BASE_NONE, false, &f_msgpackparse, { .nullptr = NULL } },
  { "reg_recorded", 0, 0, BASE_NONE, false, &f_reg_recorded, { .nullptr = NULL } },
  { "nvim_get_var", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[25] } },
  { "nvim_set_var", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[26] } },
  { "nvim_del_var", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[22] } },
  { "nvim_command", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[21] } },
  { "nvim__unpack", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[20] } },
  { "filereadable", 1, 1, 1, false, &f_filereadable, { .nullptr = NULL } },
  { "filewritable", 1, 1, 1, false, &f_filewritable, { .nullptr = NULL } },
  { "wildmenumode", 0, 0, BASE_NONE, false, &f_wildmenumode, { .nullptr = NULL } },
  { "reltimefloat", 1, 1, 1, false, &f_reltimefloat, { .nullptr = NULL } },
  { "complete_add", 1, 1, 1, false, &f_complete_add, { .nullptr = NULL } },
  { "synconcealed", 2, 2, BASE_NONE, false, &f_synconcealed, { .nullptr = NULL } },
  { "inputrestore", 0, 0, BASE_NONE, false, &f_inputrestore, { .nullptr = NULL } },
  { "screenstring", 2, 2, 1, false, &f_screenstring, { .nullptr = NULL } },
  { "assert_beeps", 1, 1, 1, false, &f_assert_beeps, { .nullptr = NULL } },
  { "assert_equal", 2, 3, 2, false, &f_assert_equal, { .nullptr = NULL } },
  { "assert_fails", 1, 5, 1, false, &f_assert_fails, { .nullptr = NULL } },
  { "assert_false", 1, 2, 1, false, &f_assert_false, { .nullptr = NULL } },
  { "assert_match", 2, 3, 2, false, &f_assert_match, { .nullptr = NULL } },
  { "gettabwinvar", 3, 4, 1, false, &f_gettabwinvar, { .nullptr = NULL } },
  { "settabwinvar", 4, 4, 4, false, &f_settabwinvar, { .nullptr = NULL } },
  { "nextnonblank", 1, 1, 1, false, &f_nextnonblank, { .nullptr = NULL } },
  { "timer_stopall", 0, 0, BASE_NONE, false, &f_timer_stopall, { .nullptr = NULL } },
  { "getchangelist", 0, 1, 1, false, &f_getchangelist, { .nullptr = NULL } },
  { "getcharsearch", 0, 0, BASE_NONE, false, &f_getcharsearch, { .nullptr = NULL } },
  { "setcharsearch", 1, 1, 1, false, &f_setcharsearch, { .nullptr = NULL } },
  { "win_screenpos", 1, 1, 1, false, &f_win_screenpos, { .nullptr = NULL } },
  { "appendbufline", 3, 3, 3, false, &f_appendbufline, { .nullptr = NULL } },
  { "getcmdwintype", 0, 0, BASE_NONE, false, &f_getcmdwintype, { .nullptr = NULL } },
  { "win_id2tabwin", 1, 1, 1, false, &f_win_id2tabwin, { .nullptr = NULL } },
  { "nvim_del_mark", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[35] } },
  { "deletebufline", 2, 3, 1, false, &f_deletebufline, { .nullptr = NULL } },
  { "complete_info", 0, 1, 1, false, &f_complete_info, { .nullptr = NULL } },
  { "reg_recording", 0, 0, BASE_NONE, false, &f_reg_recording, { .nullptr = NULL } },
  { "nvim_feedkeys", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[33] } },
  { "matchfuzzypos", 2, 3, 1, false, &f_matchfuzzypos, { .nullptr = NULL } },
  { "nvim_get_vvar", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[43] } },
  { "nvim_get_mode", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[34] } },
  { "nvim_get_proc", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[37] } },
  { "nvim_get_mark", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[36] } },
  { "searchpairpos", 3, 7, BASE_NONE, false, &f_searchpairpos, { .nullptr = NULL } },
  { "foldclosedend", 1, 1, 1, false, &f_foldclosedend, { .nullptr = NULL } },
  { "nvim_list_uis", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[29] } },
  { "setcellwidths", 1, 1, 1, false, &f_setcellwidths, { .nullptr = NULL } },
  { "getcompletion", 2, 3, 1, false, &f_getcompletion, { .nullptr = NULL } },
  { "nvim_open_win", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[30] } },
  { "win_splitmove", 2, 3, 1, false, &f_win_splitmove, { .nullptr = NULL } },
  { "buffer_exists", 1, 1, 1, false, &f_bufexists, { .nullptr = NULL } },
  { "buffer_number", 0, 1, 1, false, &f_bufnr, { .nullptr = NULL } },
  { "file_readable", 1, 1, 1, false, &f_filereadable, { .nullptr = NULL } },
  { "nvim_strwidth", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[32] } },
  { "nvim_set_vvar", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[44] } },
  { "assert_nobeep", 1, 1, 1, false, &f_assert_nobeep, { .nullptr = NULL } },
  { "assert_report", 1, 1, 1, false, &f_assert_report, { .nullptr = NULL } },
  { "sign_undefine", 0, 1, 1, false, &f_sign_undefine, { .nullptr = NULL } },
  { "nvim_win_hide", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[31] } },
  { "reg_executing", 0, 0, BASE_NONE, false, &f_reg_executing, { .nullptr = NULL } },
  { "nvim__id_float", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[46] } },
  { "nvim__id_array", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[45] } },
  { "dictwatcheradd", 3, 3, BASE_NONE, false, &f_dictwatcheradd, { .nullptr = NULL } },
  { "dictwatcherdel", 3, 3, BASE_NONE, false, &f_dictwatcherdel, { .nullptr = NULL } },
  { "last_buffer_nr", 0, 0, BASE_NONE, false, &f_last_buffer_nr, { .nullptr = NULL } },
  { "complete_check", 0, 0, BASE_NONE, false, &f_complete_check, { .nullptr = NULL } },
  { "foldtextresult", 1, 1, 1, false, &f_foldtextresult, { .nullptr = NULL } },
  { "nvim_err_write", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[48] } },
  { "garbagecollect", 0, 1, BASE_NONE, false, &f_garbagecollect, { .nullptr = NULL } },
  { "sign_getplaced", 0, 2, 1, false, &f_sign_getplaced, { .nullptr = NULL } },
  { "tabpagebuflist", 0, 1, 1, false, &f_tabpagebuflist, { .nullptr = NULL } },
  { "nvim_list_bufs", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[51] } },
  { "nvim_list_wins", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[52] } },
  { "nvim_out_write", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[53] } },
  { "nvim_open_term", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[54] } },
  { "sign_placelist", 1, 1, 1, false, &f_sign_placelist, { .nullptr = NULL } },
  { "nvim_parse_cmd", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[55] } },
  { "nvim_set_hl_ns", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[59] } },
  { "assert_inrange", 3, 4, 3, false, &f_assert_inrange, { .nullptr = NULL } },
  { "windowsversion", 0, 0, BASE_NONE, false, &f_windowsversion, { .nullptr = NULL } },
  { "nvim_win_close", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[63] } },
  { "nvim__buf_stats", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[91] } },
  { "nvim_buf_attach", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[74] } },
  { "nvim_buf_delete", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[76] } },
  { "nvim_create_buf", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[73] } },
  { "getcmdcompltype", 0, 0, BASE_NONE, false, &f_getcmdcompltype, { .nullptr = NULL } },
  { "getcmdscreenpos", 0, 0, BASE_NONE, false, &f_getcmdscreenpos, { .nullptr = NULL } },
  { "nvim_del_keymap", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[82] } },
  { "sign_getdefined", 0, 1, 1, false, &f_sign_getdefined, { .nullptr = NULL } },
  { "nvim_get_keymap", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[88] } },
  { "nvim_get_option", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[87] } },
  { "nvim_list_chans", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[83] } },
  { "digraph_getlist", 0, 1, 1, false, &f_digraph_getlist, { .nullptr = NULL } },
  { "digraph_setlist", 1, 1, 1, false, &f_digraph_setlist, { .nullptr = NULL } },
  { "strdisplaywidth", 1, 2, 1, false, &f_strdisplaywidth, { .nullptr = NULL } },
  { "nvim_set_keymap", 4, 4, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[89] } },
  { "nvim_set_option", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[86] } },
  { "assert_notequal", 2, 3, 2, false, &f_assert_notequal, { .nullptr = NULL } },
  { "assert_notmatch", 2, 3, 2, false, &f_assert_notmatch, { .nullptr = NULL } },
  { "highlight_exists", 1, 1, 1, false, &f_hlexists, { .nullptr = NULL } },
  { "sign_unplacelist", 1, 1, 1, false, &f_sign_unplacelist, { .nullptr = NULL } },
  { "nvim_del_autocmd", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[97] } },
  { "assert_exception", 1, 2, BASE_NONE, false, &f_assert_exception, { .nullptr = NULL } },
  { "getcursorcharpos", 0, 1, 1, false, &f_getcursorcharpos, { .nullptr = NULL } },
  { "nvim_get_context", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[98] } },
  { "setcursorcharpos", 1, 3, 1, false, &f_setcursorcharpos, { .nullptr = NULL } },
  { "nvim_buf_del_var", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[115] } },
  { "nvim_win_del_var", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[104] } },
  { "nvim__screenshot", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[110] } },
  { "nvim_win_get_buf", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[100] } },
  { "nvim_buf_get_var", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[113] } },
  { "nvim_win_get_var", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[102] } },
  { "nvim_win_set_var", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[103] } },
  { "nvim_buf_set_var", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[114] } },
  { "nvim_win_set_buf", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[101] } },
  { "nvim_input_mouse", 6, 6, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[105] } },
  { "prompt_getprompt", 1, 1, 1, false, &f_prompt_getprompt, { .nullptr = NULL } },
  { "prompt_setprompt", 2, 2, 1, false, &f_prompt_setprompt, { .nullptr = NULL } },
  { "assert_equalfile", 2, 3, 1, false, &f_assert_equalfile, { .nullptr = NULL } },
  { "nvim_err_writeln", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[108] } },
  { "nvim_get_hl_by_id", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[117] } },
  { "nvim_buf_is_valid", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[140] } },
  { "nvim_win_is_valid", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[138] } },
  { "nvim__get_runtime", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[137] } },
  { "nvim_buf_get_name", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[122] } },
  { "nvim_buf_set_name", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[120] } },
  { "nvim_buf_del_mark", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[118] } },
  { "nvim_buf_set_mark", 5, 5, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[119] } },
  { "nvim_buf_get_mark", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[121] } },
  { "nvim__get_lib_dir", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[124] } },
  { "nvim_get_autocmds", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[141] } },
  { "nvim__get_hl_defs", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[126] } },
  { "nvim_get_commands", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[143] } },
  { "nvim_load_context", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[127] } },
  { "nvim_buf_set_text", 6, 6, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[125] } },
  { "nvim_buf_get_text", 6, 6, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[128] } },
  { "nvim__inspect_cell", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[149] } },
  { "nvim_buf_get_lines", 4, 4, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[155] } },
  { "nvim_buf_set_lines", 5, 5, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[156] } },
  { "nvim_buf_is_loaded", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[158] } },
  { "nvim_call_function", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[151] } },
  { "nvim_exec_autocmds", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[157] } },
  { "nvim_get_color_map", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[161] } },
  { "nvim_get_chan_info", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[148] } },
  { "nvim_list_tabpages", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[160] } },
  { "win_move_separator", 2, 2, 1, false, &f_win_move_separator, { .nullptr = NULL } },
  { "prompt_setcallback", 2, 2, 1, false, &f_prompt_setcallback, { .nullptr = NULL } },
  { "nvim_win_set_width", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[164] } },
  { "nvim_win_get_width", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[163] } },
  { "nvim_win_set_hl_ns", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[153] } },
  { "nvim_get_hl_by_name", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[165] } },
  { "nvim_set_hl_ns_fast", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[166] } },
  { "nvim_buf_line_count", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[167] } },
  { "nvim_win_set_height", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[172] } },
  { "nvim_win_get_height", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[171] } },
  { "nvim_buf_get_keymap", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[168] } },
  { "nvim_buf_set_keymap", 5, 5, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[169] } },
  { "nvim_buf_del_keymap", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[170] } },
  { "nvim_buf_get_offset", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[173] } },
  { "nvim_create_augroup", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[174] } },
  { "nvim_win_get_config", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[180] } },
  { "nvim__id_dictionary", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[178] } },
  { "nvim_clear_autocmds", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[177] } },
  { "nvim_win_set_config", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[179] } },
  { "nvim_get_namespaces", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[184] } },
  { "nvim_buf_get_option", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[185] } },
  { "nvim_buf_set_option", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[181] } },
  { "nvim_win_get_option", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[182] } },
  { "nvim_win_set_option", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[183] } },
  { "prompt_setinterrupt", 2, 2, 1, false, &f_prompt_setinterrupt, { .nullptr = NULL } },
  { "win_move_statusline", 2, 2, 1, false, &f_win_move_statusline, { .nullptr = NULL } },
  { "test_write_list_log", 1, 1, BASE_NONE, false, &f_test_write_list_log, { .nullptr = NULL } },
  { "nvim_create_autocmd", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[186] } },
  { "nvim_win_set_cursor", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[189] } },
  { "nvim_win_get_cursor", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[188] } },
  { "nvim_command_output", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[187] } },
  { "nvim_buf_get_number", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[191] } },
  { "nvim_win_get_number", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[190] } },
  { "nvim_win_get_tabpage", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[211] } },
  { "nvim_buf_set_extmark", 5, 5, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[192] } },
  { "nvim_buf_del_extmark", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[193] } },
  { "nvim_get_current_buf", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[198] } },
  { "nvim_set_current_buf", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[204] } },
  { "nvim_set_current_dir", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[203] } },
  { "nvim_eval_statusline", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[194] } },
  { "nvim_get_option_info", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[200] } },
  { "nvim_tabpage_get_var", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[207] } },
  { "nvim_tabpage_set_var", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[210] } },
  { "nvim_tabpage_del_var", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[208] } },
  { "nvim_tabpage_get_win", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[209] } },
  { "nvim_get_current_win", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[199] } },
  { "nvim_set_current_win", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[206] } },
  { "nvim__runtime_inspect", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[212] } },
  { "nvim_buf_get_commands", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[213] } },
  { "nvim_buf_get_extmarks", 5, 5, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[214] } },
  { "nvim_create_namespace", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[215] } },
  { "nvim_del_current_line", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[216] } },
  { "nvim_del_user_command", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[217] } },
  { "nvim_get_runtime_file", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[219] } },
  { "nvim_get_current_line", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[220] } },
  { "nvim_get_option_value", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[221] } },
  { "nvim_parse_expression", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[222] } },
  { "nvim_set_current_line", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[225] } },
  { "nvim_set_option_value", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[226] } },
  { "nvim_tabpage_is_valid", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[227] } },
  { "nvim_win_get_position", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[228] } },
  { "nvim_replace_termcodes", 4, 4, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[239] } },
  { "nvim_buf_add_highlight", 6, 6, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[237] } },
  { "nvim_tabpage_list_wins", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[240] } },
  { "nvim_get_hl_id_by_name", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[243] } },
  { "nvim_get_color_by_name", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[244] } },
  { "nvim__buf_redraw_range", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[230] } },
  { "nvim_get_proc_children", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[238] } },
  { "nvim_del_augroup_by_id", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[229] } },
  { "nvim_call_dict_function", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[245] } },
  { "test_garbagecollect_now", 0, 0, BASE_NONE, false, &f_test_garbagecollect_now, { .nullptr = NULL } },
  { "nvim_list_runtime_paths", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[248] } },
  { "nvim_tabpage_get_number", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[249] } },
  { "nvim_create_user_command", 3, 3, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[251] } },
  { "nvim_buf_clear_highlight", 4, 4, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[252] } },
  { "nvim_buf_clear_namespace", 4, 4, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[253] } },
  { "nvim_del_augroup_by_name", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[254] } },
  { "nvim_get_current_tabpage", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[255] } },
  { "nvim_set_current_tabpage", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[256] } },
  { "nvim_buf_get_changedtick", 1, 1, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[257] } },
  { "nvim_get_all_options_info", 0, 0, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[258] } },
  { "nvim_buf_del_user_command", 2, 2, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[259] } },
  { "nvim_buf_set_virtual_text", 5, 5, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[260] } },
  { "nvim_buf_get_extmark_by_id", 4, 4, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[261] } },
  { "nvim_select_popupmenu_item", 4, 4, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[262] } },
  { "nvim_buf_create_user_command", 4, 4, BASE_NONE, false, &api_wrapper, { .api_handler = &method_handlers[263] } },
  { NULL, 0, 0, BASE_NONE, false, NULL, { .nullptr = NULL } },
};

int find_internal_func_hash(const char *str, size_t len)
{
  int low = 0, high = 0;
  switch (len) {
    case 2: switch (str[0]) {
      case 'i': low = 0; high = 1; break;
      case 'o': low = 1; high = 2; break;
      case 't': low = 2; high = 3; break;
      default: break;
    }
    break;
    case 3: switch (str[0]) {
      case 'a': low = 3; high = 6; break;
      case 'c': low = 6; high = 8; break;
      case 'e': low = 8; high = 9; break;
      case 'g': low = 9; high = 10; break;
      case 'h': low = 10; high = 11; break;
      case 'l': low = 11; high = 13; break;
      case 'm': low = 13; high = 16; break;
      case 'p': low = 16; high = 17; break;
      case 's': low = 17; high = 18; break;
      case 't': low = 18; high = 19; break;
      case 'x': low = 19; high = 20; break;
      default: break;
    }
    break;
    case 4: switch (str[3]) {
      case 'D': low = 20; high = 21; break;
      case 'b': low = 21; high = 22; break;
      case 'c': low = 22; high = 23; break;
      case 'd': low = 23; high = 25; break;
      case 'e': low = 25; high = 28; break;
      case 'h': low = 28; high = 31; break;
      case 'l': low = 31; high = 34; break;
      case 'm': low = 34; high = 35; break;
      case 'n': low = 35; high = 38; break;
      case 'q': low = 38; high = 39; break;
      case 's': low = 39; high = 41; break;
      case 't': low = 41; high = 44; break;
      case 'v': low = 44; high = 45; break;
      case 'y': low = 45; high = 46; break;
      default: break;
    }
    break;
    case 5: switch (str[1]) {
      case 'a': low = 46; high = 48; break;
      case 'c': low = 48; high = 49; break;
      case 'h': low = 49; high = 50; break;
      case 'i': low = 50; high = 51; break;
      case 'k': low = 51; high = 52; break;
      case 'l': low = 52; high = 53; break;
      case 'm': low = 53; high = 54; break;
      case 'n': low = 54; high = 56; break;
      case 'o': low = 56; high = 59; break;
      case 'p': low = 59; high = 60; break;
      case 'r': low = 60; high = 62; break;
      case 's': low = 62; high = 64; break;
      case 't': low = 64; high = 66; break;
      case 'u': low = 66; high = 67; break;
      case 'y': low = 67; high = 68; break;
      default: break;
    }
    break;
    case 6: switch (str[5]) {
      case '6': low = 68; high = 69; break;
      case 'd': low = 69; high = 76; break;
      case 'e': low = 76; high = 82; break;
      case 'f': low = 82; high = 83; break;
      case 'g': low = 83; high = 87; break;
      case 'h': low = 87; high = 88; break;
      case 'l': low = 88; high = 90; break;
      case 'm': low = 90; high = 91; break;
      case 'n': low = 91; high = 92; break;
      case 'p': low = 92; high = 93; break;
      case 'r': low = 93; high = 97; break;
      case 's': low = 97; high = 101; break;
      case 't': low = 101; high = 108; break;
      case 'v': low = 108; high = 110; break;
      case 'x': low = 110; high = 112; break;
      default: break;
    }
    break;
    case 7: switch (str[2]) {
      case '2': low = 112; high = 113; break;
      case '3': low = 113; high = 114; break;
      case 'a': low = 114; high = 120; break;
      case 'b': low = 120; high = 124; break;
      case 'c': low = 124; high = 125; break;
      case 'd': low = 125; high = 126; break;
      case 'e': low = 126; high = 128; break;
      case 'f': low = 128; high = 130; break;
      case 'g': low = 130; high = 131; break;
      case 'l': low = 131; high = 133; break;
      case 'n': low = 133; high = 138; break;
      case 'r': low = 138; high = 141; break;
      case 's': low = 141; high = 146; break;
      case 't': low = 146; high = 151; break;
      case 'u': low = 151; high = 152; break;
      case 'v': low = 152; high = 154; break;
      case 'x': low = 154; high = 157; break;
      default: break;
    }
    break;
    case 8: switch (str[3]) {
      case '2': low = 157; high = 158; break;
      case '_': low = 158; high = 159; break;
      case 'a': low = 159; high = 160; break;
      case 'b': low = 160; high = 162; break;
      case 'c': low = 162; high = 170; break;
      case 'd': low = 170; high = 175; break;
      case 'f': low = 175; high = 182; break;
      case 'l': low = 182; high = 183; break;
      case 'm': low = 183; high = 189; break;
      case 'n': low = 189; high = 191; break;
      case 'o': low = 191; high = 194; break;
      case 'p': low = 194; high = 201; break;
      case 's': low = 201; high = 204; break;
      case 't': low = 204; high = 208; break;
      case 'u': low = 208; high = 209; break;
      case 'w': low = 209; high = 213; break;
      case 'x': low = 213; high = 214; break;
      case 'y': low = 214; high = 215; break;
      default: break;
    }
    break;
    case 9: switch (str[4]) {
      case '2': low = 215; high = 217; break;
      case 'D': low = 217; high = 218; break;
      case '_': low = 218; high = 224; break;
      case 'a': low = 224; high = 229; break;
      case 'c': low = 229; high = 233; break;
      case 'd': low = 233; high = 234; break;
      case 'e': low = 234; high = 240; break;
      case 'f': low = 240; high = 243; break;
      case 'g': low = 243; high = 244; break;
      case 'h': low = 244; high = 245; break;
      case 'i': low = 245; high = 250; break;
      case 'l': low = 250; high = 252; break;
      case 'm': low = 252; high = 254; break;
      case 'n': low = 254; high = 255; break;
      case 'o': low = 255; high = 258; break;
      case 'r': low = 258; high = 259; break;
      case 's': low = 259; high = 260; break;
      case 't': low = 260; high = 262; break;
      case 'u': low = 262; high = 265; break;
      case 'x': low = 265; high = 266; break;
      default: break;
    }
    break;
    case 10: switch (str[5]) {
      case '_': low = 266; high = 268; break;
      case 'a': low = 268; high = 273; break;
      case 'b': low = 273; high = 275; break;
      case 'c': low = 275; high = 277; break;
      case 'd': low = 277; high = 281; break;
      case 'e': low = 281; high = 282; break;
      case 'f': low = 282; high = 286; break;
      case 'g': low = 286; high = 288; break;
      case 'h': low = 288; high = 290; break;
      case 'i': low = 290; high = 292; break;
      case 'l': low = 292; high = 294; break;
      case 'm': low = 294; high = 296; break;
      case 'n': low = 296; high = 302; break;
      case 'o': low = 302; high = 303; break;
      case 'p': low = 303; high = 305; break;
      case 'q': low = 305; high = 306; break;
      case 'r': low = 306; high = 309; break;
      case 's': low = 309; high = 311; break;
      case 't': low = 311; high = 316; break;
      case 'w': low = 316; high = 317; break;
      default: break;
    }
    break;
    case 11: switch (str[5]) {
      case '_': low = 317; high = 320; break;
      case 'a': low = 320; high = 322; break;
      case 'c': low = 322; high = 324; break;
      case 'd': low = 324; high = 329; break;
      case 'e': low = 329; high = 334; break;
      case 'f': low = 334; high = 335; break;
      case 'g': low = 335; high = 337; break;
      case 'h': low = 337; high = 339; break;
      case 'i': low = 339; high = 341; break;
      case 'm': low = 341; high = 343; break;
      case 'n': low = 343; high = 346; break;
      case 'o': low = 346; high = 349; break;
      case 'p': low = 349; high = 351; break;
      case 'r': low = 351; high = 355; break;
      case 's': low = 355; high = 359; break;
      case 't': low = 359; high = 360; break;
      case 'u': low = 360; high = 361; break;
      case 'v': low = 361; high = 362; break;
      case 'x': low = 362; high = 363; break;
      default: break;
    }
    break;
    case 12: switch (str[2]) {
      case 'b': low = 363; high = 364; break;
      case 'd': low = 364; high = 365; break;
      case 'e': low = 365; high = 370; break;
      case 'g': low = 370; high = 373; break;
      case 'i': low = 373; high = 378; break;
      case 'l': low = 378; high = 382; break;
      case 'm': low = 382; high = 383; break;
      case 'n': low = 383; high = 384; break;
      case 'p': low = 384; high = 385; break;
      case 'r': low = 385; high = 386; break;
      case 's': low = 386; high = 391; break;
      case 't': low = 391; high = 393; break;
      case 'x': low = 393; high = 394; break;
      default: break;
    }
    break;
    case 13: switch (str[5]) {
      case '_': low = 394; high = 395; break;
      case 'a': low = 395; high = 398; break;
      case 'c': low = 398; high = 399; break;
      case 'd': low = 399; high = 403; break;
      case 'e': low = 403; high = 406; break;
      case 'f': low = 406; high = 408; break;
      case 'g': low = 408; high = 412; break;
      case 'h': low = 412; high = 413; break;
      case 'l': low = 413; high = 416; break;
      case 'm': low = 416; high = 417; break;
      case 'o': low = 417; high = 418; break;
      case 'p': low = 418; high = 419; break;
      case 'r': low = 419; high = 422; break;
      case 's': low = 422; high = 424; break;
      case 't': low = 424; high = 426; break;
      case 'u': low = 426; high = 427; break;
      case 'w': low = 427; high = 428; break;
      case 'x': low = 428; high = 429; break;
      default: break;
    }
    break;
    case 14: switch (str[5]) {
      case '_': low = 429; high = 431; break;
      case 'a': low = 431; high = 433; break;
      case 'b': low = 433; high = 434; break;
      case 'e': low = 434; high = 437; break;
      case 'g': low = 437; high = 440; break;
      case 'l': low = 440; high = 442; break;
      case 'o': low = 442; high = 444; break;
      case 'p': low = 444; high = 446; break;
      case 's': low = 446; high = 447; break;
      case 't': low = 447; high = 448; break;
      case 'w': low = 448; high = 450; break;
      default: break;
    }
    break;
    case 15: switch (str[5]) {
      case '_': low = 450; high = 451; break;
      case 'b': low = 451; high = 453; break;
      case 'c': low = 453; high = 454; break;
      case 'd': low = 454; high = 457; break;
      case 'g': low = 457; high = 460; break;
      case 'l': low = 460; high = 461; break;
      case 'p': low = 461; high = 463; break;
      case 's': low = 463; high = 466; break;
      case 't': low = 466; high = 468; break;
      default: break;
    }
    break;
    case 16: switch (str[9]) {
      case '_': low = 468; high = 469; break;
      case 'a': low = 469; high = 471; break;
      case 'c': low = 471; high = 475; break;
      case 'd': low = 475; high = 477; break;
      case 'e': low = 477; high = 478; break;
      case 'g': low = 478; high = 481; break;
      case 's': low = 481; high = 484; break;
      case 't': low = 484; high = 487; break;
      case 'u': low = 487; high = 488; break;
      case 'w': low = 488; high = 489; break;
      default: break;
    }
    break;
    case 17: switch (str[16]) {
      case 'd': low = 489; high = 492; break;
      case 'e': low = 492; high = 495; break;
      case 'k': low = 495; high = 498; break;
      case 'r': low = 498; high = 499; break;
      case 's': low = 499; high = 502; break;
      case 't': low = 502; high = 505; break;
      default: break;
    }
    break;
    case 18: switch (str[5]) {
      case '_': low = 505; high = 506; break;
      case 'b': low = 506; high = 509; break;
      case 'c': low = 509; high = 510; break;
      case 'e': low = 510; high = 511; break;
      case 'g': low = 511; high = 513; break;
      case 'l': low = 513; high = 514; break;
      case 'o': low = 514; high = 515; break;
      case 't': low = 515; high = 516; break;
      case 'w': low = 516; high = 519; break;
      default: break;
    }
    break;
    case 19: switch (str[14]) {
      case '_': low = 519; high = 521; break;
      case 'c': low = 521; high = 522; break;
      case 'e': low = 522; high = 527; break;
      case 'f': low = 527; high = 528; break;
      case 'g': low = 528; high = 529; break;
      case 'o': low = 529; high = 533; break;
      case 'p': low = 533; high = 538; break;
      case 'r': low = 538; high = 539; break;
      case 's': low = 539; high = 540; break;
      case 't': low = 540; high = 542; break;
      case 'u': low = 542; high = 547; break;
      default: break;
    }
    break;
    case 20: switch (str[17]) {
      case 'a': low = 547; high = 550; break;
      case 'b': low = 550; high = 552; break;
      case 'd': low = 552; high = 553; break;
      case 'i': low = 553; high = 554; break;
      case 'n': low = 554; high = 555; break;
      case 'v': low = 555; high = 558; break;
      case 'w': low = 558; high = 561; break;
      default: break;
    }
    break;
    case 21: switch (str[5]) {
      case '_': low = 561; high = 562; break;
      case 'b': low = 562; high = 564; break;
      case 'c': low = 564; high = 565; break;
      case 'd': low = 565; high = 567; break;
      case 'g': low = 567; high = 570; break;
      case 'p': low = 570; high = 571; break;
      case 's': low = 571; high = 573; break;
      case 't': low = 573; high = 574; break;
      case 'w': low = 574; high = 575; break;
      default: break;
    }
    break;
    case 22: switch (str[10]) {
      case 'c': low = 575; high = 576; break;
      case 'd': low = 576; high = 577; break;
      case 'g': low = 577; high = 578; break;
      case 'l': low = 578; high = 579; break;
      case 'o': low = 579; high = 580; break;
      case 'r': low = 580; high = 582; break;
      case 'u': low = 582; high = 583; break;
      default: break;
    }
    break;
    case 23: switch (str[5]) {
      case 'c': low = 583; high = 584; break;
      case 'g': low = 584; high = 585; break;
      case 'l': low = 585; high = 586; break;
      case 't': low = 586; high = 587; break;
      default: break;
    }
    break;
    case 24: switch (str[11]) {
      case '_': low = 587; high = 588; break;
      case 'e': low = 588; high = 590; break;
      case 'g': low = 590; high = 591; break;
      case 'r': low = 591; high = 593; break;
      case 't': low = 593; high = 594; break;
      default: break;
    }
    break;
    case 25: switch (str[9]) {
      case 'a': low = 594; high = 595; break;
      case 'd': low = 595; high = 596; break;
      case 's': low = 596; high = 597; break;
      default: break;
    }
    break;
    case 26: switch (str[5]) {
      case 'b': low = 597; high = 598; break;
      case 's': low = 598; high = 599; break;
      default: break;
    }
    break;
    case 28: low = 599; high = 600; break;
    default: break;
  }
  for (int i = low; i < high; i++) {
    if (!memcmp(str, functions[i].name, len)) {
      return i;
    }
  }
  return -1;
}

