#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void ui_ext_msg_set_pos(int row, _Bool scrolled);
static _Bool other_sourcing_name(void);
static char *get_emsg_source(void) FUNC_ATTR_MALLOC FUNC_ATTR_WARN_UNUSED_RESULT;
static char *get_emsg_lnum(void) FUNC_ATTR_MALLOC FUNC_ATTR_WARN_UNUSED_RESULT;
static _Bool emsg_multiline(const char *s, _Bool multiline);
static _Bool semsgv(const char *fmt, va_list ap);
static void msg_semsg_event(void **argv);
static void add_msg_hist(const char *s, int len, int attr, _Bool multiline);
static void add_msg_hist_multiattr(const char *s, int len, int attr, _Bool multiline, HlMessage multiattr);
static void hit_return_msg(void);
static void msg_home_replace_attr(char *fname, int attr);
static char *screen_puts_mbyte(char *s, int l, int attr);
static void msg_ext_emit_chunk(void);
static void msg_puts_display(const char *str, int maxlen, int attr, int recurse);
static void inc_msg_scrolled(void);
static void store_sb_text(char **sb_str, char *s, int attr, int *sb_col, int finish);
static msgchunk_T *msg_sb_start(msgchunk_T *mps);
static msgchunk_T *disp_sb_line(int row, msgchunk_T *smp);
static void t_puts(int *t_col, const char *t_s, const char *s, int attr);
static void msg_puts_printf(const char *str, const ptrdiff_t maxlen);
static int do_more_prompt(int typed_char);
static void msg_screen_putchar(int c, int attr);
static void redir_write(const char *const str, const ptrdiff_t maxlen);
static int copy_char(const char *from, char *to, _Bool lowercase) FUNC_ATTR_NONNULL_ALL;
static char *console_dialog_alloc(const char *message, char *buttons, _Bool has_hotkey[]);
static char *msg_show_console_dialog(char *message, char *buttons, int dfltbutton) FUNC_ATTR_NONNULL_RET;
static void copy_hotkeys_and_msg(const char *message, char *buttons, int default_button_idx, const _Bool has_hotkey[], char *hotkeys_ptr);
#include "nvim/func_attr.h"
