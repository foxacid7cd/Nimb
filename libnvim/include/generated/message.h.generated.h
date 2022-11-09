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
DLLEXPORT void msg_grid_set_pos(int row, _Bool scrolled);
DLLEXPORT _Bool msg_use_grid(void);
DLLEXPORT void msg_grid_validate(void);
DLLEXPORT int msg(char *s);
DLLEXPORT int verb_msg(char *s);
DLLEXPORT int msg_attr(const char *s, const int attr) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT void msg_multiline_attr(const char *s, int attr, _Bool check_int, _Bool *need_clear) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void msg_multiattr(HlMessage hl_msg, const char *kind, _Bool history);
DLLEXPORT _Bool msg_attr_keep(const char *s, int attr, _Bool keep, _Bool multiline) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT char *msg_strtrunc(char *s, int force);
DLLEXPORT void trunc_string(char *s, char *buf, int room_in, int buflen);
DLLEXPORT int smsg(const char *s, ...) FUNC_ATTR_PRINTF(1, 2);
DLLEXPORT int smsg_attr(int attr, const char *s, ...) FUNC_ATTR_PRINTF(2, 3);
DLLEXPORT int smsg_attr_keep(int attr, const char *s, ...) FUNC_ATTR_PRINTF(2, 3);
DLLEXPORT void reset_last_sourcing(void);
DLLEXPORT void msg_source(int attr);
DLLEXPORT int emsg_not_now(void);
DLLEXPORT _Bool emsg(const char *s);
DLLEXPORT void emsg_invreg(int name);
DLLEXPORT _Bool semsg(const char *const fmt, ...) FUNC_ATTR_PRINTF(1, 2);
DLLEXPORT _Bool semsg_multiline(const char *const fmt, ...);
DLLEXPORT void iemsg(const char *s);
DLLEXPORT void siemsg(const char *s, ...);
DLLEXPORT void internal_error(char *where);
DLLEXPORT void msg_schedule_semsg(const char *const fmt, ...) FUNC_ATTR_PRINTF(1, 2);
DLLEXPORT char *msg_trunc_attr(char *s, _Bool force, int attr);
DLLEXPORT char *msg_may_trunc(_Bool force, char *s);
DLLEXPORT void hl_msg_free(HlMessage hl_msg);
DLLEXPORT int delete_first_msg(void);
DLLEXPORT void ex_messages(void *const eap_p) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void msg_end_prompt(void);
DLLEXPORT void wait_return(int redraw);
DLLEXPORT void set_keep_msg(char *s, int attr);
DLLEXPORT void msgmore(long n);
DLLEXPORT void msg_ext_set_kind(const char *msg_kind);
DLLEXPORT void msg_start(void);
DLLEXPORT void msg_starthere(void);
DLLEXPORT void msg_putchar(int c);
DLLEXPORT void msg_putchar_attr(int c, int attr);
DLLEXPORT void msg_outnum(long n);
DLLEXPORT void msg_home_replace(char *fname);
DLLEXPORT void msg_home_replace_hl(char *fname);
DLLEXPORT int msg_outtrans(char *str);
DLLEXPORT int msg_outtrans_attr(const char *str, int attr);
DLLEXPORT int msg_outtrans_len(const char *str, int len);
DLLEXPORT char *msg_outtrans_one(char *p, int attr);
DLLEXPORT int msg_outtrans_len_attr(const char *msgstr, int len, int attr);
DLLEXPORT void msg_make(char *arg);
DLLEXPORT int msg_outtrans_special(const char *strstart, _Bool from, int maxlen);
DLLEXPORT char *str2special_save(const char *const str, const _Bool replace_spaces, const _Bool replace_lt) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_MALLOC FUNC_ATTR_NONNULL_RET;
DLLEXPORT const char *str2special(const char **const sp, const _Bool replace_spaces, const _Bool replace_lt) FUNC_ATTR_NONNULL_ALL FUNC_ATTR_WARN_UNUSED_RESULT FUNC_ATTR_NONNULL_RET;
DLLEXPORT void str2specialbuf(const char *sp, char *buf, size_t len) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void msg_prt_line(char *s, int list);
DLLEXPORT void msg_puts(const char *s);
DLLEXPORT void msg_puts_title(const char *s);
DLLEXPORT void msg_outtrans_long_attr(char *longstr, int attr);
DLLEXPORT void msg_outtrans_long_len_attr(char *longstr, int len, int attr);
DLLEXPORT void msg_puts_attr(const char *const s, const int attr);
DLLEXPORT void msg_puts_attr_len(const char *const str, const ptrdiff_t len, int attr) FUNC_ATTR_NONNULL_ALL;
DLLEXPORT void msg_printf_attr(const int attr, const char *const fmt, ...) FUNC_ATTR_NONNULL_ARG(2) FUNC_ATTR_PRINTF(2, 3);
DLLEXPORT _Bool message_filtered(char *msg);
DLLEXPORT int msg_scrollsize(void);
DLLEXPORT _Bool msg_do_throttle(void);
DLLEXPORT void msg_scroll_up(_Bool may_throttle, _Bool zerocmd);
DLLEXPORT void msg_scroll_flush(void);
DLLEXPORT void msg_reset_scroll(void);
DLLEXPORT void may_clear_sb_text(void);
DLLEXPORT void sb_text_start_cmdline(void);
DLLEXPORT void sb_text_restart_cmdline(void);
DLLEXPORT void sb_text_end_cmdline(void);
DLLEXPORT void clear_sb_text(int all);
DLLEXPORT void show_sb_text(void);
DLLEXPORT void msg_sb_eol(void);
DLLEXPORT int msg_use_printf(void);
DLLEXPORT void msg_moremsg(int full);
DLLEXPORT void repeat_message(void);
DLLEXPORT void msg_clr_eos(void);
DLLEXPORT void msg_clr_eos_force(void);
DLLEXPORT void msg_clr_cmdline(void);
DLLEXPORT int msg_end(void);
DLLEXPORT void msg_ext_ui_flush(void);
DLLEXPORT void msg_ext_flush_showmode(void);
DLLEXPORT void msg_ext_clear(_Bool force);
DLLEXPORT void msg_ext_clear_later(void);
DLLEXPORT void msg_ext_check_clear(void);
DLLEXPORT _Bool msg_ext_is_visible(void);
DLLEXPORT void msg_check(void);
DLLEXPORT int redirecting(void);
DLLEXPORT void verbose_enter(void);
DLLEXPORT void verbose_leave(void);
DLLEXPORT void verbose_enter_scroll(void);
DLLEXPORT void verbose_leave_scroll(void);
DLLEXPORT void verbose_stop(void);
DLLEXPORT int verbose_open(void);
DLLEXPORT void give_warning(char *message, _Bool hl) FUNC_ATTR_NONNULL_ARG(1);
DLLEXPORT void give_warning2(char *const message, char *const a1, _Bool hl);
DLLEXPORT void msg_advance(int col);
DLLEXPORT int do_dialog(int type, char *title, char *message, char *buttons, int dfltbutton, char *textfield, int ex_cmd);
DLLEXPORT void display_confirm_msg(void);
DLLEXPORT int vim_dialog_yesno(int type, char *title, char *message, int dflt);
DLLEXPORT int vim_dialog_yesnocancel(int type, char *title, char *message, int dflt);
DLLEXPORT int vim_dialog_yesnoallcancel(int type, char *title, char *message, int dflt);
#include "nvim/func_attr.h"
