#define DEFINE_FUNC_ATTRIBUTES
#include "nvim/func_attr.h"
#undef DEFINE_FUNC_ATTRIBUTES
static void win_border_redr_title(win_T *wp, ScreenGrid *grid, int col);
static void win_redr_border(win_T *wp);
static void redraw_win_signcol(win_T *wp);
static _Bool hsep_connected(win_T *wp, WindowCorner corner);
static _Bool vsep_connected(win_T *wp, WindowCorner corner);
static void draw_vsep_win(win_T *wp);
static void draw_hsep_win(win_T *wp);
static int get_corner_sep_connector(win_T *wp, WindowCorner corner);
static void draw_sep_connectors_win(win_T *wp);
static void win_update(win_T *wp, DecorProviders *providers);
#include "nvim/func_attr.h"
