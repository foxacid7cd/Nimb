#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static int win_fill_end(win_T *wp, int c1, int c2, int off, int width, int row, int endrow, int attr);
static int wildmenu_match_len(expand_T *xp, char_u *s);
static int skip_wildmenu_char(expand_T *xp, char_u *s);
static void msg_pos_mode(void);
static void recording_mode(int attr);
static void ui_ext_tabline_update(void);
static int get_encoded_char_adv(const char_u **p);
#include "nvim/func_attr.h"
