#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
#ifndef DLLEXPORT
#  ifdef MSWIN
#    define DLLEXPORT __declspec(dllexport)
#  else
#    define DLLEXPORT
#  endif
#endif
DLLEXPORT void terminal_init(void);
DLLEXPORT void terminal_teardown(void);
DLLEXPORT Terminal *terminal_open(buf_T *buf, TerminalOptions opts);
DLLEXPORT void terminal_close(Terminal **termpp, int status);
DLLEXPORT void terminal_check_size(Terminal *term);
DLLEXPORT _Bool terminal_enter(void);
DLLEXPORT void terminal_destroy(Terminal **termpp);
DLLEXPORT void terminal_send(Terminal *term, char *data, size_t size);
DLLEXPORT void terminal_paste(long count, char **y_array, size_t y_size);
DLLEXPORT void terminal_send_key(Terminal *term, int c);
DLLEXPORT void terminal_receive(Terminal *term, char *data, size_t len);
DLLEXPORT void terminal_get_line_attributes(Terminal *term, win_T *wp, int linenr, int *term_attrs);
DLLEXPORT Buffer terminal_buf(const Terminal *term);
DLLEXPORT _Bool terminal_running(const Terminal *term);
DLLEXPORT void on_scrollback_option_changed(Terminal *term);
#include "nvim/func_attr.h"
