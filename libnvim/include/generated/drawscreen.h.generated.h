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
DLLEXPORT void conceal_check_cursor_line(void);
DLLEXPORT _Bool default_grid_alloc(void);
DLLEXPORT void screenclear(void);
DLLEXPORT void screen_resize(int width, int height);
DLLEXPORT int update_screen(void);
DLLEXPORT void show_cursor_info(_Bool always);
DLLEXPORT void redraw_later(win_T *wp, int type) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void redraw_all_later(int type);
DLLEXPORT void screen_invalidate_highlights(void);
DLLEXPORT void redraw_curbuf_later(int type);
DLLEXPORT void redraw_buf_later(buf_T *buf, int type);
DLLEXPORT void redraw_buf_line_later(buf_T *buf, linenr_T line, _Bool force);
DLLEXPORT void redraw_buf_range_later(buf_T *buf, linenr_T firstline, linenr_T lastline);
DLLEXPORT void redraw_buf_status_later(buf_T *buf);
DLLEXPORT void status_redraw_all(void);
DLLEXPORT void status_redraw_curbuf(void);
DLLEXPORT void status_redraw_buf(buf_T *buf);
DLLEXPORT void redraw_statuslines(void);
DLLEXPORT void win_redraw_last_status(const frame_T *frp) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT void redrawWinline(win_T *wp, linenr_T lnum) FUNC_ATTR_NONNULL_ALL;
#include "nvim/func_attr.h"
